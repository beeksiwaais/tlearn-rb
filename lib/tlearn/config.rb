module TLearn
  class Config
    WORKING_DIR = File.dirname(__FILE__) + '/../../data'
    TLEARN_NAMESPACE = 'evaluator'
    NUMBER_OF_RESET_TIMEPOINTS = 3497
    DEFAULT_NUMBER_OF_SWEEPS = 1333000
    
    def initialize(config, working_dir = nil)
      @connections_config = config.delete(:connections) || {}
      @config             = config                      || {}
      @working_dir = working_dir || WORKING_DIR
    end

    def working_dir
      @working_dir
    end

    def setup_config(training_data)
      File.open("#{file_root}.cf",    "w") {|f| f.write(evaulator_config(training_data))}
    end

    def setup_fitness_data(data)
      File.open("#{file_root}.data",  "w") {|f| f.write(build_data(data))}
    end

    def setup_training_data(training_data)
      File.open("#{file_root}.reset", "w") {|f| f.write(build_reset_config(training_data))}
      File.open("#{file_root}.data",  "w") {|f| f.write(build_data(training_data))}
      File.open("#{file_root}.teach", "w") {|f| f.write(build_teach_data(training_data))}
    end
    
    def number_of_sweeps
      DEFAULT_NUMBER_OF_SWEEPS
    end

    def file_root
      "#{working_dir}/#{TLEARN_NAMESPACE}"
    end

    private

    def connections_ranges_to_strings(connections_config)
      connections_config.map{|hash| {input_to_config_string(hash.keys[0]) => input_to_config_string(hash.values[0])}}
    end

    def input_to_config_string(input)
      if input.is_a?(Hash)
        "#{input[:min]} & #{input[:max]}"
      elsif input.is_a?(Range)
        input.to_s.gsub('..','-')
      elsif input.is_a?(Array)
        values = input.map{|value| input_to_config_string(value)}
        values[0] = values[0] + " ="
        values.join(" ").gsub('one_to_one', 'one-to-one')
      else
        input
      end
    end

    def evaulator_config(training_data)
      nodes_config = {
        :nodes => @config[:number_of_nodes],
        :inputs => training_data.no_of_inputs,
        :outputs => training_data.no_of_outputs,
        :output_nodes => input_to_config_string(@config[:output_nodes])
      }

      @connections_config = connections_ranges_to_strings(@connections_config)

      output_nodes = nodes_config.delete(:output_nodes)
      node_config_strings = nodes_config.map{|key,value| "#{key.to_s.gsub('_',' ')} = #{value}" }
      node_config_strings << "output nodes are #{output_nodes}"

      connection_config_strings = @connections_config.map{|mapping| "#{mapping.keys[0]} from #{input_to_config_string(mapping.values[0])}" }
      connection_config_strings =  ["groups = #{0}"] + connection_config_strings
      
      special_config = {}
      special_config[:linear] = @config[:linear]
      special_config[:weight_limit] = @config[:weight_limit]
      special_config[:selected] = input_to_config_string(1..@config[:number_of_nodes])

      config = <<EOS
NODES:
#{node_config_strings.join("\n")}
CONNECTIONS:
#{connection_config_strings.join("\n")}
SPECIAL:
#{special_config.map{|key,value| "#{key} = #{input_to_config_string(value)}" }.join("\n")}
EOS
    end

    def build_data(training_data)
      data_file = <<EOS
distributed
#{training_data.no_of_data_values}
#{training_data.data.map{|d| d.join(" ")}.join("\n")}
EOS
    end

    def build_teach_data(training_data)
      data_strings = training_data.output_data.map{|d| d.join(" ")}
      data_strings = data_strings.each_with_index.map{|data, index| "#{index} #{data}" }
      
      teach_file = <<EOS
distributed
#{training_data.no_of_data_values}
#{data_strings.join("\n")}
EOS
    end
  
    def build_reset_config(training_data)
      reset_points = training_data.reset_points
      reset_file = <<EOS
#{reset_points.join("\n")}
EOS
    end
    
    def number_of_outputs(training_data)
      training_data.values[0].length
    end
    
  end
end