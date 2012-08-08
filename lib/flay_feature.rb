#!/usr/bin/ruby
require 'rubygems'
require 'sexp'
require 'flay'

class CukeInstance
  def initialize
    @steps = []
  end
  def steps
    @steps
  end

  def Given(regex,&block)
    define_step(regex,&block)
  end
  def When(regex,&block)
    define_step(regex,&block)
  end
  def Then(regex,&block)
    define_step(regex,&block)
  end

  def And(regex, &block)
    define_step(regex, &block)
  end

  def define_step(regex,&block)
    @steps << regex
  end

  def World(*args)
    # do nothing
  end

  def require(*args)
    # do nothing
  end

  def line_matches(line,line_no,file)
    stripped_line = line.strip.gsub(/^(And|Given|When|Then) (.*)$/,'\2')

    @steps.each_with_index do |regex,i|
      match = regex.match(stripped_line)
      if match
        s_exp = Sexp.new(:call,nil,"method_#{i}".to_sym, Sexp.new(:arglist,*(match.captures.collect {|str| Sexp.new(:str,str)})))
        s_exp.line = line_no
        s_exp.file = file
        return s_exp
      end
    end

    return nil
  end
end

class Flay

  def process_feature file
    @file = file

    @instance ||= begin
                    new_inst = CukeInstance.new

                    Dir.glob('features/step_definitions/**/*.rb').each do |file_name|
                      new_inst.instance_eval File.read(file_name)
                    end
                    new_inst
                  end

    @tree = Sexp.new
    @current_node = @tree
    @current_node << :block

    File.read(file).each_with_index do |line,line_no|
      @line_no = line_no + 1

      if line =~ /Scenario|Background/
        @current_node = @tree
        @current_node << s(:iter,s(:call,nil,:scen_defn,s(:arglist)),nil)
        @current_node = @current_node.last
      else
        step_id = @instance.line_matches(line,@line_no,file)
        @current_node << step_id if step_id
      end
    end

    return @tree
  end

  def s(*args)
    s_exp = Sexp.new(*args)
    s_exp.file = @file
    s_exp.line = @line_no
    s_exp
  end
end

