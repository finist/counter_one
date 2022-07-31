module CounterOne
  class Counter

    attr_reader :model, :relation, :options

    def initialize(model, relation, options)
      @model = model
      @relation = [relation].flatten
      @options = options
    end

    def update_counter(record, operator, changed_record = nil)
      counter_record = record
      klass = model

      relation.each do |rel|
        unless klass.reflect_on_association(rel)
          raise "Can't find relation #{rel} for #{klass.to_s}"
        end

        counter_record = counter_record.send(rel)
        klass = counter_record.class

        return unless counter_record
      end

      if options[:only]
        unless options[:only].is_a?(Proc)
          raise ArgumentError.new(":only must be a Proc with conditions")
        end

        return unless options[:only].call(record)
      end

      if changed_record
        return if options[:only] ? condition_not_changed?(record, changed_record) : relation_id_not_changed?(record)
      end

      if counter_record
        column = options[:column] || "#{record.class.to_s.tableize}_count"

        if counter_record.is_a?(ActiveRecord::Associations::CollectionProxy)
          counter_record.each { |r| r.send(operator, column) }
        else
          counter_record.send(operator, column)
        end
      end
    end

    def recalculate_scope
      options[:recalculate_scope]
    end

    def relation_chain
      klass = model

      relation.each_with_object([]) { |rel, chain|
        chain << klass.reflect_on_association(rel).chain.map(&:name).reverse
        klass = rel.to_s.classify.constantize
      }.flatten
    end

    private

    def condition_not_changed?(record, changed_record)
      options[:only].call(record) == options[:only].call(changed_record)
    end

    def relation_id_not_changed?(record)
      relation_fk = model.reflect_on_association(relation_chain.first).foreign_key
      record.saved_changes[relation_fk].blank?
    end
  end
end
