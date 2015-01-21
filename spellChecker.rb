require 'set'
require 'strscan'

class TokenScanner
  def initialize(str)
    @stringScanner = StringScanner.new(str)
  end

  def isWord(s)
    return true if s.match(/[\w']+/)
    return false
  end

  def scanNext
    nextToken = scanWord
    nextToken = scanNonWord if nextToken.nil? # next token is not a word
    nil if nextToken.nil?
    nextToken
  end

  def scanWord
    # a word may contain any letter a-z plus the single quote character (')
    word = @stringScanner.scan(/['\w]+/)
    word
  end

  def scanNonWord # everything else (punctuation, spaces, etc.) is a non-word
    nonWord =  @stringScanner.scan(/[^'\w]+/)
    nonWord
  end
end

class Dictionary
  def initialize(filename)
    @dict = Set.new
    arr = getWordArrFromFile(filename)
    arr.each do |s|
      @dict.add(s.downcase)
    end
  end

  # returns array of words from a file, eliminating non-words (punctuation)
  def getWordArrFromFile(filename)
    file = File.read(filename)
    file.gsub!(/[^a-z ']/i, ' ')
    file.split(' ')
  end

  def getNumWords
    @dict.size
  end

  def isDictionaryWord(string)
    @dict.include?(string.downcase)
  end

  def print
    p @dict
  end
end

class Corrector
  # Returns a new set that contains the same elements as the input set,
  # except the case (all lowercase, or uppercase first letter) matches that
  # of the input string.
  def matchCase(incorrectWord, corrections)
    revised = Set.new
    capitalizeFirst = if (/[[:upper:]]/.match(incorrectWord[0])) then
      true
    else
      false
    end
    # (/[[:upper:]]/.match(incorrectWord[0])) ? capitalizeFirst = true : capitalizeFirst = false
    corrections.each do |corr|
      if capitalizeFirst
        capitalized = corr[0].upcase + corr[1..-1].downcase
        revised.add(capitalized)
      else
        revised.add(corr.downcase)
      end
    end
    revised
  end
end

# gets spelling suggestions based on "swapped letter" typos.
class SwapCorrector < Corrector
  def initialize(dictionary)
    @dict = dictionary
    @corrections = Set.new
  end

  def getCorrections(wrong)
    return [] if wrong.eql? "" or @dict.isDictionaryWord(wrong)
    @corrections = Set.new # contents should not persist between calls
    i = 0
    wrong.downcase.each_char do |c|
      swapped = wrong.clone
      swapped[i] = wrong[i+1]
      swapped[i+1] = wrong[i]
      @corrections.add(swapped) if @dict.isDictionaryWord(swapped)
      i += 1
      break if i > wrong.length-2
    end
    matchCase(wrong, @corrections)
  end
end

# gets spelling suggestions based on a text file.
class FileCorrector < Corrector
  def initialize(filename)
    @map = Hash.new
    File.readlines(filename).each do |line|
      i = line.index(',')
      if !i or i >= line.length or line.count(',') != 1
        raise "FileCorrector: invalid input"
      end
      # raise "FileCorrector: invalid input" if !i or i >= line.length or line.count(',') != 1
      arr = line.split(',')
      arr.collect! {|w| w.gsub(/\s+/, "")}
      word = arr[0]
      corr = arr[1]
      corrections = Set.new
      corrections = @map[word] if @map[word]
      corrections.add(corr)
      @map[word] = corrections
    end
  end

  def getCorrections(wrong)
    return [] if wrong.eql? "" or !@map[wrong.downcase]
    matchCase(wrong, @map[wrong.downcase])
  end
end


class SpellChecker
  def initialize(c, d)
    @corr = c
    @dict = d
  end

  def getNextInt(min, max)
    opt = Integer(STDIN.gets) rescue nil until not opt.nil?
    until Integer(opt) >= min and Integer(opt) <= max
      opt = STDIN.gets.chomp.to_i
    end
    opt
  end

  def checkDocument(input, output)
    # fresh output file
    File.open(output, 'w') { |f| f.write("") }
    # process input
    File.open(input, "r").each_line do |line|
      # puts "next line to process: >#{line}<"
      tokenScanner = TokenScanner.new(line)
      token = tokenScanner.scanNext
      while not token.nil?
        if @dict.isDictionaryWord(token) or not tokenScanner.isWord(token)
          # write token to output file as is
          File.open(output, 'a') { |f| f.print("#{token}") }
        else # token is misspelled word; get corrections
          puts "The word \"#{token}\" is not in the dictionary"
          puts "Enter the number corresponding with the appropriate action:"
          puts "0: Ignore and continue"
          puts "1: Replace with another word"
          corrections = @corr.getCorrections(token).sort
          j = 0
          corrections.each_with_index do |c, i|
            i += 1
            puts "#{i+1}: Replace with \"#{c}\""
            j = i
          end
          opt = getNextInt(0, j+1)
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
        token = tokenScanner.scanNext
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
corrector = if (ARGV[3].eql? "SWAP") then
  SwapCorrector.new(dictionary)
else
  FileCorrector.new(ARGV[3])
end
# (ARGV[3].eql? "SWAP") ? corrector = SwapCorrector.new(dictionary) : corrector = FileCorrector.new(ARGV[3])
spellchkr = SpellChecker.new(corrector, dictionary)
spellchkr.checkDocument(input, output)