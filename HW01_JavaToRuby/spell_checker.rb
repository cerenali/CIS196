require 'set'
require 'strscan'

class TokenScanner
  def initialize(str)
    @string_scanner = StringScanner.new(str)
  end

  def is_word(s)
    return true if s.match(/[\w']+/)
    return false
  end

  def scan_next
    next_token = scan_word
    next_token ||= scan_nonword # next token is not a word
    nil if next_token.nil?
    next_token
  end

  def scan_word
    # a word may contain any letter a-z plus the single quote character (')
    word = @string_scanner.scan(/['\w]+/)
    word
  end

  def scan_nonword # everything else is a non-word
    nonword =  @string_scanner.scan(/[^'\w]+/)
    nonword
  end
end

class Dictionary
  def initialize(filename)
    @dict = Set.new
    arr = get_words_from_file(filename)
    arr.each do |s|
      @dict.add(s.downcase)
    end
  end

  # returns array of words from a file, eliminating non-words
  def get_words_from_file(filename)
    file = File.read(filename)
    file.gsub!(/[^a-z ']/i, ' ')
    file.split(' ')
  end

  def is_dictionary_word(string)
    @dict.include?(string.downcase)
  end

  def print
    p @dict
  end
end

class Corrector
  def match_case(incorrect_word, corrections)
    corrections_with_matched_case = Set.new
    capitalize_first = if (/[[:upper:]]/.match(incorrect_word[0])) then
      true
    else
      false
    end
    corrections.each do |corr|
      if capitalize_first
        capitalized = corr[0].upcase + corr[1..-1].downcase
        corrections_with_matched_case.add(capitalized)
      else
        corrections_with_matched_case.add(corr.downcase)
      end
    end
    corrections_with_matched_case
  end
end

# gets spelling suggestions based on "swapped letter" typos.
class SwapCorrector < Corrector
  def initialize(dictionary)
    @dict = dictionary
    @corrections = Set.new
  end

  def get_corrections(wrong)
    return [] if wrong == "" || @dict.is_dictionary_word(wrong)
    @corrections = Set.new
    i = 0
    wrong.downcase.each_char do |c|
      swapped = wrong.clone
      swapped[i] = wrong[i+1]
      swapped[i+1] = wrong[i]
      @corrections.add(swapped) if @dict.is_dictionary_word(swapped)
      i += 1
      break if i > wrong.length-2
    end
    match_case(wrong, @corrections)
  end
end

# gets spelling suggestions based on a text file.
class FileCorrector < Corrector
  def initialize(filename)
    @map = Hash.new
    File.readlines(filename).each do |line|
      i = line.index(',')
      if !i || i >= line.length || line.count(',') != 1
        raise "FileCorrector: invalid input"
      end
      arr = line.split(',')
      arr.collect! {|w| w.gsub(/\s+/, "")}
      word = arr[0]
      correction = arr[1]
      word.downcase!
      corrections = @map.fetch(word) if @map.fetch(word)
      corrections ||= Set.new
      corrections.add(correction)
      @map[word] = corrections
    end
  end

  def get_corrections(wrong)
    return [] if wrong == "" || !@map.fetch(wrong.downcase)
    match_case(wrong, @map.fetch(wrong.downcase))
  end
end


class SpellChecker
  def initialize(c, d)
    @corr = c
    @dict = d
  end

  def get_next_int(min, max)
    opt = Integer(STDIN.gets) rescue nil until not opt.nil?
    until Integer(opt) >= min && Integer(opt) <= max
      opt = STDIN.gets.chomp.to_i
    end
    opt
  end

  def check_document(input, output)
    File.open(output, 'w') { |f| f.write("") } # fresh output file
    File.open(input, "r").each_line do |line| # process input
      token_scanner = TokenScanner.new(line)
      token = token_scanner.scan_next
      while token
        if @dict.is_dictionary_word(token) || !token_scanner.is_word(token)
          File.open(output, 'a') { |f| f.print("#{token}") }
        else
          puts "The word \"#{token}\" is not in the dictionary\n" +
               "Enter the number corresponding with the appropriate action:\n" +
               "0: Ignore and continue\n" +
               "1: Replace with another word"
          corrections = @corr.get_corrections(token).sort
          j = 0
          corrections.each_with_index do |c, i|
            i += 1
            puts "#{i+1}: Replace with \"#{c}\""
            j = i
          end
          opt = get_next_int(0, j+1)
          case opt
          when 0 # do nothing
            str = token
          when 1 # replace with next entered word
            str = STDIN.gets.chomp
          else # select from corrections
            str = corrections[opt-2]
          end
          File.open(output, 'a') { |f| f.print("#{str}") }
        end
        token = token_scanner.scan_next
      end
    end
  end
end

unless ARGV.length == 4
  puts "Usage: ruby spellChecker.rb <in> <out> <dictionary> <corrector>\n"
  puts "<corrector> is either SWAP or the path to a corrections file.\n"
  exit
end

input = ARGV[0]
output = ARGV[1]
dictionary = Dictionary.new(ARGV[2])
corrector = if (ARGV[3] == "SWAP") then
  SwapCorrector.new(dictionary)
else
  FileCorrector.new(ARGV[3])
end
spellchkr = SpellChecker.new(corrector, dictionary)
spellchkr.check_document(input, output)