require 'csv'

module NickNameMappingUtil
  def self.load_mapping_list
    list = {}
    CSV.foreach('app_demo_verification_service/ext_lib/name_mapping.csv') do |row|
      row.each_index do |index|
        cell_data = row[index]
        row_mapping_data = row.dup
        row_mapping_data.delete_at(index)
        list[cell_data] =
          list[cell_data] = list[cell_data].nil? ? row_mapping_data : list[cell_data] | row_mapping_data
      end
    end
    list
  end
end

NickNameList = NickNameMappingUtil.load_mapping_list
