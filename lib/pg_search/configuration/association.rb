module PgSearch
  class Configuration
    class Association
      attr_reader :columns
      
      def initialize(model, name, column_names)
        @model = model
        @name = name
        @columns = Array(column_names).map do |column_name, weight|
          Column.new(column_name, weight, @model, self)
        end
      end
      
      def table_name
        @model.reflect_on_association(@name).table_name
      end
      
      def join(primary_key)
        selects = columns.map do |column|
          "string_agg(#{column.full_name}, ' ') AS #{column.alias}"
        end.join(", ")
        relation = @model.joins(@name).select("#{primary_key} AS id, #{selects}").group(primary_key)
        "LEFT OUTER JOIN (#{relation.to_sql}) #{subselect_alias} ON #{subselect_alias}.id = #{primary_key}"
      end
      
      def subselect_alias
        subselect_name = ["pg_search", table_name, @name, "subselect"].compact.join('_')
        "pg_search_#{MD5.hexdigest(subselect_name)}"
      end
    end
  end
end
