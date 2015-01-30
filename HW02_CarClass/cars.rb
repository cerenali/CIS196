class Car
  @@count = 0
  attr_accessor :brand, :year, :condition
  def initialize(brand, year, condition)
    @brand = brand
    @year = year
    @condition = condition
    @@count += 1
  end

  def print
    puts "brand: #{@brand}"
    puts "year manufactured: #{@year}"
    puts "condition: #{@condition}"
    puts "================================="
  end

  def self.get_count
    return @@count
  end

  def self.decr_count
    @@count -= 1
  end
end

def add_car(garage)
  puts "enter car brand: "
  brand = gets.chomp
  puts "enter year car was manufactured: "
  year = gets.chomp.to_i
  puts "enter car condition (abysmal, fair, good, like new, etc.): "
  condition = gets.chomp
  car = Car.new(brand, year, condition)
  garage.push(car)
end

def sort_list(garage)
  garage.sort{|a, b| a.year <=> b.year}
end

garage = []

# main run loop
quit = false
while !quit
  puts "(1) add car to garage"
  puts "(2) remove a car"
  puts "(3) show a car"
  puts "(4) show all cars"
  puts "(5) sort cars by year"
  puts "(6) show number of cars in garage"
  puts "(7) quit"
  option = gets.chomp.to_i
  case option
  when 1
    garage = add_car(garage)
  when 2
    puts "which car do you want to remove? (enter number between 0 and #{(garage.length-1 > 0) ? garage.length-1 : 0}) "
    i = gets.chomp.to_i
    (garage.delete_at(i) && Car.decr_count) rescue puts "something went wrong! please enter valid input"
  when 3
    puts "which car do you want to show? (enter number between 0 and #{(garage.length-1 > 0) ? garage.length-1 : 0}) "
    i = gets.chomp.to_i
    garage[i].print rescue puts "something went wrong! please enter valid input"
  when 4
    puts "================================="
    garage.each do |car|
      car.print
    end
  when 5
    garage = sort_list(garage)
    puts "cars have been sorted by year!"
  when 6
    puts "there are #{Car.get_count} cars in the garage"
  when 7
    quit = true
    puts "goodbye!"
  else
    puts "Invalid input — please enter an integer between 1 and 6"
  end
end
