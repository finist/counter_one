module CounterOne
  module Extensions
    extend ActiveSupport::Concern

    module ClassMethods

      attr_reader :counter_one_cache

      def counter_one(relation, options = {})
        @counter_one_cache ||= []

        @counter_one_cache << Counter.new(self, relation, options)

        on = [options[:on]].flatten.compact

        after_create  :increment_counters if on.empty? || on.include?(:create)
        after_destroy :decrement_counters if on.empty? || on.include?(:destroy)
        after_update  :update_counters if on.empty? || on.include?(:update)
      end

      def counter_one_recalculate(relation = nil)
        counters = relation ? counter_one_cache.select { |counter| counter.relation == [relation].flatten } : counter_one_cache
        counters.each { |counter| recalculate_counters(counter) }
      end

      private

      def recalculate_counters(counter)
        counter_relation_chain = counter.relation_chain

        joins_chain = counter_relation_chain.reverse.inject() { |value, key| { key => value } }
        counter_relation_table_name = counter_relation_chain.last.to_s.classify.constantize.table_name
        
        counter_relation_chain.last.to_s.classify.constantize.find_in_batches do |batch|
          batch_ids = batch.pluck(:id)

          result = self
                    .then { |scope| counter.recalculate_scope.values.include?(:joins) ? scope : scope.joins(joins_chain) }
                    .merge(counter.recalculate_scope)
                    .where(counter_relation_table_name => { id: batch_ids })
                    .group("#{counter_relation_table_name}.id")
                    .count

          batch_ids.each_with_object(result) { |id, res| res[id] = 0 if !res.include?(id) }

          result.each do |key, value|
            column = counter.options[:column] || "#{self.to_s.tableize}_count"
            counter.relation_chain.last.to_s.classify.constantize.find(key).update(column => value)
          end
        end
      end

    end

    private

    def increment_counters
      self.class.counter_one_cache.each do |counter|
        counter.update_counter(self, :increment!)
      end
    end

    def decrement_counters
      self.class.counter_one_cache.each do |counter|
        counter.update_counter(self, :decrement!)
      end
    end

    def update_counters
      self.class.counter_one_cache.each do |counter|
        counter.update_counter(record_before_save, :decrement!, self)
        counter.update_counter(self, :increment!, record_before_save)
      end
    end

    def record_before_save
      record = self.dup

      self.saved_changes.each do |key, value|
        record.assign_attributes(key => value.first)
      end

      record
    end
  end
end
