# frozen_string_literal: true
require 'models/user'
require 'models/product'
require 'models/comment'
require 'models/category'
require 'models/category_user'

RSpec.describe CounterOne do
  before do
    Product.instance_variable_set(:@counter_one_cache, [])
    Comment.instance_variable_set(:@counter_one_cache, [])
  end

  context 'with :on option' do
    after do
      if Product._create_callbacks.map(&:filter).include?(:increment_counters)
        Product.skip_callback(:create, :after, :increment_counters)
      end

      if Product._destroy_callbacks.map(&:filter).include?(:decrement_counters)
        Product.skip_callback(:destroy, :after, :decrement_counters)
      end

      if Product._update_callbacks.map(&:filter).include?(:update_counters)
        Product.skip_callback(:update, :after, :update_counters)
      end
    end

    it 'should change when :on equal :create on create' do
      user = User.create

      Product.counter_one(:user, on: :create)

      expect { Product.create(user: user) }.to change { user.reload.products_count }.from(0).to(1)
    end
    
    it 'should not change when :on not equal :create on create' do
      user = User.create
      
      Product.counter_one(:user, on: :update)

      expect { Product.create(user: user) }.to_not change { user.reload.products_count }
    end
    
    it 'should change when :on equal :destroy on destroy' do
      user = User.create(products_count: 1)

      Product.counter_one(:user, on: :destroy)

      product = Product.create(user: user)

      expect { product.destroy }.to change { user.reload.products_count }.from(1).to(0)
    end
    
    it 'should not change when :on not equal :destroy on destroy' do
      user = User.create(products_count: 1)
      
      Product.counter_one(:user, on: :update)

      product = Product.create(user: user)

      expect { product.destroy }.to_not change { user.reload.products_count }
    end
    
    it 'should change when :on equal :update on update' do
      user = User.create(products_count: 1)
      user_2 = User.create

      Product.counter_one(:user, on: :update)

      product = Product.create(user: user)

      expect { product.update(user: user_2) }.to change { 
        [user.reload.products_count, user_2.reload.products_count]
      }.from([1, 0]).to([0, 1])
    end
    
    it 'should not change when :on not equal :update on update' do
      user = User.create(products_count: 1)
      user_2 = User.create
      
      Product.counter_one(:user, on: :destroy)

      product = Product.create(user: user)

      expect { product.update(user: user_2) }.to_not change {
        [user.reload.products_count, user_2.reload.products_count] 
      }
    end
  end

  context 'with single relation' do
    it 'should not change counter without relation' do
      user = User.create

      Product.counter_one(:user)

      expect { Product.create }.to_not change { user.reload.products_count }
    end
    
    it 'should increase counter on create' do
      user = User.create

      Product.counter_one(:user)

      expect { Product.create(user: user) }.to change { user.reload.products_count }.from(0).to(1)
    end

    it 'should decrease counter on destroy' do
      user = User.create

      Product.counter_one(:user)

      product = Product.create(user: user)

      expect { product.destroy }.to change { user.reload.products_count }.from(1).to(0)
    end
    
    it 'should increase counter with :only on create' do
      user = User.create

      Product.counter_one(:user, column: :approved_products_count, only: ->(record) { record.approved? })

      Product.create(user: user)

      expect { Product.create(user: user, approved: true) }.to change { user.reload.approved_products_count }.from(0).to(1)
    end
    
    it 'should decrease counter with :only on destroy' do
      user = User.create

      Product.counter_one(:user, column: :approved_products_count, only: ->(record) { record.approved? })

      Product.create(user: user)
      product = Product.create(user: user, approved: true)

      expect { product.destroy }.to change { user.reload.approved_products_count }.from(1).to(0)
    end

    it 'should increase counter on add relation id' do
      user = User.create
      product = Product.create

      Product.counter_one(:user)

      expect { product.update(user: user) }.to change { user.reload.products_count }.from(0).to(1)
    end
    
    it 'should decrease counter on remove relation id' do
      user = User.create

      Product.counter_one(:user)

      product = Product.create(user: user)

      expect { product.update(user: nil) }.to change { user.reload.products_count }.from(1).to(0)
    end

    it 'should increase counter for new relation on change relation id' do
      user = User.create
      user_2 = User.create

      Product.counter_one(:user)

      product = Product.create(user: user)

      expect { product.update(user: user_2) }.to change { user_2.reload.products_count }.from(0).to(1)
    end
    
    it 'should decrease counter for old relation on change relation id' do
      user = User.create
      user_2 = User.create

      Product.counter_one(:user)

      product = Product.create(user: user)

      expect { product.update(user: user_2) }.to change { user.reload.products_count }.from(1).to(0)
    end

    it 'should increase counter on update when change attribute for :only condition' do
      user = User.create

      Product.counter_one(:user, column: :approved_products_count, only: ->(record) { record.approved? })

      product = Product.create(user: user)

      expect { product.update(approved: true) }.to change { user.reload.approved_products_count }.from(0).to(1)
    end
    
    it 'should decrease counter on update with unset attribute for :only condition' do
      user = User.create

      Product.counter_one(:user, column: :approved_products_count, only: ->(record) { record.approved? })

      product = Product.create(user: user, approved: true)

      expect { product.update(approved: false) }.to change { user.reload.approved_products_count }.from(1).to(0)
    end

    it 'should not call decrease! for record on update when change attribute not for :only condition' do
      user = User.create

      Product.counter_one(:user)

      product = Product.create(user: user, name: 'test')

      expect_any_instance_of(User).to_not receive(:decrease!)

      product.update(name: 'test 2')
    end
    
    it 'should not call increase! for record on update when change attribute not for :only condition' do
      user = User.create

      Product.counter_one(:user)

      product = Product.create(user: user, name: 'test')

      expect_any_instance_of(User).to_not receive(:increase!)

      product.update(name: 'test 2')
    end

    it 'should decrease counter on remove relation id' do
      user = User.create

      Product.counter_one(:user)

      product = Product.create(user: user)

      expect { product.update(user: nil) }.to change { user.reload.products_count }.from(1).to(0)
    end

    it 'should raise error if relation not found' do
      user = User.create

      Product.counter_one(:user_x)

      expect { Product.create(user: user) }.to raise_error(RuntimeError, "Can't find relation user_x for Product")
    end

    context 'on recalculation' do
      it 'should update counters' do
        user = User.create
        user_2 = User.create

        Product.create(user: user)
        Product.create(user: user)

        Product.create(user: user_2)

        Product.counter_one(:user)

        expect { Product.counter_one_recalculate }.to change { user.reload.products_count }.from(0).to(2)
      end
      
      it 'should update counters to zero if relation has`t items' do
        user = User.create(products_count: 1)

        Product.counter_one(:user)

        expect { Product.counter_one_recalculate }.to change { user.reload.products_count }.from(1).to(0)
      end
      
      it 'should update multiple counters' do
        user = User.create

        Product.create(user: user)
        Product.create(user: user, approved: true)

        Product.counter_one(:user)
        Product.counter_one(:user, column: :approved_products_count, recalculate_scope: Product.where(approved: true))

        expect { Product.counter_one_recalculate }.to change { 
          user.reload.slice(:products_count, :approved_products_count).values 
        }.from([0, 0]).to([2, 1])
      end

      it 'should update counters with relation param' do
        user = User.create
        user_2 = User.create

        Product.create(user: user)
        Product.create(user: user)

        Product.create(user: user_2)

        Product.counter_one(:user)

        expect { Product.counter_one_recalculate(:user) }.to change { user.reload.products_count }.from(0).to(2)
      end

      it 'should update counters with :recalculate_scope' do
        user = User.create
        user_2 = User.create

        Product.create(user: user)
        Product.create(user: user, approved: true)

        Product.create(user: user_2)

        Product.counter_one(:user, recalculate_scope: Product.where(approved: true))

        expect { Product.counter_one_recalculate }.to change { user.reload.products_count }.from(0).to(1)
      end    
    end
  end

  context 'with multi level relation' do
    it 'should not change counter without relation' do
      user = User.create
      product = Product.create(user: user)

      Comment.counter_one([:product, :user])

      expect { Comment.create }.to_not change { user.reload.comments_count }
    end

    it 'should increase counter on create' do
      user = User.create
      product = Product.create(user: user)

      Comment.counter_one([:product, :user])

      expect { Comment.create(product: product) }.to change { user.reload.comments_count }.from(0).to(1)
    end

    it 'should decrease counter on destroy' do
      user = User.create
      product = Product.create(user: user)

      Comment.counter_one([:product, :user])

      comment = Comment.create(product: product)

      expect { comment.destroy }.to change { user.reload.comments_count }.from(1).to(0)
    end

    it 'should increase counter with :only on create' do
      user = User.create
      product = Product.create(user: user)

      Comment.counter_one([:product, :user], column: :approved_comments_count, only: ->(record) { record.approved? })

      Comment.create(product: product)

      expect { Comment.create(product: product, approved: true) }.to change { user.reload.approved_comments_count }.from(0).to(1)
    end

    it 'should decrease counter with :only on destroy' do
      user = User.create
      product = Product.create(user: user)

      Comment.counter_one([:product, :user], column: :approved_comments_count, only: ->(record) { record.approved? })

      Comment.create(product: product)
      comment = Comment.create(product: product, approved: true)

      expect { comment.destroy }.to change { user.reload.approved_comments_count }.from(1).to(0)
    end

    it 'should increase counter on add relation id' do
      user = User.create
      product = Product.create(user: user)
      comment = Comment.create

      Comment.counter_one([:product, :user])

      expect { comment.update(product: product) }.to change { user.reload.comments_count }.from(0).to(1)
    end

    it 'should decrease counter on remove relation id' do
      user = User.create
      product = Product.create(user: user)
      
      Comment.counter_one([:product, :user])

      comment = Comment.create(product: product)

      expect { comment.update(product: nil) }.to change { user.reload.comments_count }.from(1).to(0)
    end

    it 'should increase counter for new relation on change relation id' do
      user_1 = User.create
      user_2 = User.create

      product_1 = Product.create(user: user_1)
      product_2 = Product.create(user: user_2)

      Comment.counter_one([:product, :user])

      comment = Comment.create(product: product_1)

      expect { comment.update(product: product_2) }.to change { user_2.reload.comments_count }.from(0).to(1)
    end
    
    it 'should decrease counter for old relation on change relation id' do
      user_1 = User.create
      user_2 = User.create

      product_1 = Product.create(user: user_1)
      product_2 = Product.create(user: user_2)

      Comment.counter_one([:product, :user])

      comment = Comment.create(product: product_1)

      expect { comment.update(product: product_2) }.to change { user_1.reload.comments_count }.from(1).to(0)
    end

    it 'should increase counter on update when change attribute for :only condition' do
      user = User.create
      product = Product.create(user: user)

      Comment.counter_one([:product, :user], column: :approved_comments_count, only: ->(record) { record.approved? })

      comment = Comment.create(product: product)

      expect { comment.update(approved: true) }.to change { user.reload.approved_comments_count }.from(0).to(1)
    end
    
    it 'should decrease counter on update with unset attribute for :only condition' do
      user = User.create
      product = Product.create(user: user)

      Comment.counter_one([:product, :user], column: :approved_comments_count, only: ->(record) { record.approved? })

      comment = Comment.create(product: product, approved: true)

      expect { comment.update(approved: false) }.to change { user.reload.approved_comments_count }.from(1).to(0)
    end

    it 'should not call decrease! for record on update when change attribute not for :only condition' do
      user = User.create
      product = Product.create(user: user)

      Comment.counter_one([:product, :user])

      comment = Comment.create(product: product, body: 'test')

      expect_any_instance_of(User).to_not receive(:decrease!)

      comment.update(body: 'test 2')
    end
    
    it 'should not call increase! for record on update when change attribute not for :only condition' do
      user = User.create
      product = Product.create(user: user)

      Comment.counter_one([:product, :user])

      comment = Comment.create(product: product, body: 'test')

      expect_any_instance_of(User).to_not receive(:increase!)

      comment.update(body: 'test 2')
    end

    it 'should decrease counter on remove relation id' do
      user = User.create
      product = Product.create(user: user)

      Comment.counter_one([:product, :user])

      comment = Comment.create(product: product)

      expect { comment.update(product: nil) }.to change { user.reload.comments_count }.from(1).to(0)
    end

    it 'should raise error if relation not found' do
      user = User.create
      product = Product.create(user: user)

      Comment.counter_one([:product, :user_x])

      expect { Comment.create(product: product) }.to raise_error(RuntimeError, "Can't find relation user_x for Product")
    end

    context 'on recalculation' do
      it 'should update counters' do
        user = User.create
        user_2 = User.create
        
        product = Product.create(user: user)
        product_2 = Product.create(user: user_2)

        Comment.create(product: product)
        Comment.create(product: product)
        
        Comment.create(product: product_2)

        Comment.counter_one([:product, :user])

        expect { Comment.counter_one_recalculate }.to change { user.reload.comments_count }.from(0).to(2)
      end

      it 'should update counters to zero if relation has`t items' do
        user = User.create(comments_count: 1)
        product = Product.create(user: user)

        Comment.counter_one([:product, :user])

        expect { Comment.counter_one_recalculate }.to change { user.reload.comments_count }.from(1).to(0)
      end

      it 'should update multiple counters' do
        user = User.create
        product = Product.create(user: user)

        Comment.create(product: product)
        Comment.create(product: product, approved: true)

        Comment.counter_one([:product, :user])
        Comment.counter_one([:product, :user], column: :approved_comments_count, recalculate_scope: Comment.where(approved: true))

        expect { Comment.counter_one_recalculate }.to change { 
          user.reload.slice(:comments_count, :approved_comments_count).values 
        }.from([0, 0]).to([2, 1])
      end

      it 'should update counters with relation param' do
        user = User.create
        user_2 = User.create

        product = Product.create(user: user)
        product_2 = Product.create(user: user_2)

        Comment.create(product: product)
        Comment.create(product: product)

        Comment.create(product: product_2)

        Comment.counter_one([:product, :user])

        expect { Comment.counter_one_recalculate([:product, :user]) }.to change { user.reload.comments_count }.from(0).to(2)
      end
      
      it 'should update counters with :recalculate_scope' do
        user = User.create
        user_2 = User.create

        product = Product.create(user: user)
        product_2 = Product.create(user: user_2)

        Comment.create(product: product)
        Comment.create(product: product, approved: true)

        Comment.create(product: product_2)

        Comment.counter_one([:product, :user], recalculate_scope: Comment.where(approved: true))

        expect { Comment.counter_one_recalculate([:product, :user]) }.to change { user.reload.comments_count }.from(0).to(1)
      end
    end
  end

  context 'with has_one through relation' do
    it 'should not change counter without relation' do
      user = User.create
      product = Product.create(user: user)

      Comment.has_one(:user, through: :product)
      Comment.counter_one(:user)

      expect { Comment.create }.to_not change { user.reload.comments_count }
    end

    it 'should increase counter on create' do
      user = User.create
      product = Product.create(user: user)

      Comment.has_one(:user, through: :product)
      Comment.counter_one(:user)

      expect { Comment.create(product: product) }.to change { user.reload.comments_count }.from(0).to(1)
    end    

    it 'should decrease counter on destroy' do
      user = User.create
      product = Product.create(user: user)

      Comment.has_one(:user, through: :product)
      Comment.counter_one(:user)

      comment = Comment.create(product: product)

      expect { comment.destroy }.to change { user.reload.comments_count }.from(1).to(0)
    end

    it 'should increase counter with :only on create' do
      user = User.create
      product = Product.create(user: user)

      Comment.has_one(:user, through: :product)
      Comment.counter_one(:user, column: :approved_comments_count, only: ->(record) { record.approved? })

      Comment.create(product: product)

      expect { Comment.create(product: product, approved: true) }.to change { user.reload.approved_comments_count }.from(0).to(1)
    end
    
    it 'should decrease counter with :only on destroy' do
      user = User.create
      product = Product.create(user: user)

      Comment.has_one(:user, through: :product)
      Comment.counter_one(:user, column: :approved_comments_count, only: ->(record) { record.approved? })

      Comment.create(product: product)
      comment = Comment.create(product: product, approved: true)

      expect { comment.destroy }.to change { user.reload.approved_comments_count }.from(1).to(0)
    end

    it 'should increase counter on add relation id' do
      user = User.create
      product = Product.create(user: user)

      Comment.has_one(:user, through: :product)
      Comment.counter_one(:user)

      comment = Comment.create

      expect { comment.update(product: product) }.to change { user.reload.comments_count }.from(0).to(1)
    end
    
    it 'should decrease counter on remove relation id' do
      user = User.create
      product = Product.create(user: user)

      Comment.has_one(:user, through: :product)
      Comment.counter_one(:user)

      comment = Comment.create(product: product)

      expect { comment.update(product: nil) }.to change { user.reload.comments_count }.from(1).to(0)
    end

    it 'should increase counter for new relation on change relation id' do
      user = User.create
      user_2 = User.create

      product = Product.create(user: user)
      product_2 = Product.create(user: user_2)

      Comment.has_one(:user, through: :product)
      Comment.counter_one(:user)

      comment = Comment.create(product: product)

      expect { comment.update(product: product_2) }.to change { user_2.reload.comments_count }.from(0).to(1)
    end
    
    it 'should decrease counter for old relation on change relation id' do
      user = User.create
      user_2 = User.create

      product = Product.create(user: user)
      product_2 = Product.create(user: user_2)

      Comment.has_one(:user, through: :product)
      Comment.counter_one(:user)

      comment = Comment.create(product: product)

      expect { comment.update(product: product_2) }.to change { user.reload.comments_count }.from(1).to(0)
    end

    it 'should increase counter on update when change attribute for :only condition' do
      user = User.create
      product = Product.create(user: user)

      Comment.has_one(:user, through: :product)
      Comment.counter_one(:user, column: :approved_comments_count, only: ->(record) { record.approved? })

      comment = Comment.create(product: product)

      expect { comment.update(approved: true) }.to change { user.reload.approved_comments_count }.from(0).to(1)
    end
    
    it 'should decrease counter on update with unset attribute for :only condition' do
      user = User.create
      product = Product.create(user: user)

      Comment.has_one(:user, through: :product)
      Comment.counter_one(:user, column: :approved_comments_count, only: ->(record) { record.approved? })

      comment = Comment.create(product: product, approved: true)

      expect { comment.update(approved: nil) }.to change { user.reload.approved_comments_count }.from(1).to(0)
    end

    it 'should not call decrease! for record on update when change attribute not for :only condition' do
      user = User.create
      product = Product.create(user: user)

      Comment.has_one(:user, through: :product)
      Product.counter_one(:user)

      comment = Comment.create(product: product, body: 'test')

      expect_any_instance_of(User).to_not receive(:decrease!)

      comment.update(body: 'test 2')
    end
    
    it 'should not call increase! for record on update when change attribute not for :only condition' do
      user = User.create
      product = Product.create(user: user)

      Comment.has_one(:user, through: :product)
      Product.counter_one(:user)

      comment = Comment.create(product: product, body: 'test')

      expect_any_instance_of(User).to_not receive(:increase!)

      comment.update(body: 'test 2')
    end

    it 'should decrease counter on remove relation id' do
      user = User.create
      product = Product.create(user: user)

      Comment.has_one(:user, through: :product)
      Comment.counter_one(:user)

      comment = Comment.create(product: product)

      expect { comment.update(product: nil) }.to change { user.reload.comments_count }.from(1).to(0)
    end

    it 'should raise error if relation not found' do
      user = User.create
      product = Product.create(user: user)

      Comment.counter_one(:user_x)

      expect { Comment.create(product: product) }.to raise_error(RuntimeError, "Can't find relation user_x for Comment")
    end

    context 'on recalculation' do
      it 'should update counters' do
        user = User.create
        user_2 = User.create

        product = Product.create(user: user)
        product_2 = Product.create(user: user_2)

        Comment.create(product: product)
        Comment.create(product: product)

        Comment.create(product: product_2)

        Comment.has_one(:user, through: :product)
        Comment.counter_one(:user)

        expect { Comment.counter_one_recalculate }.to change { user.reload.comments_count }.from(0).to(2)
      end

      it 'should update counters to zero if relation has`t items' do
        user = User.create(comments_count: 1)
        product = Product.create(user: user)

        Comment.has_one(:user, through: :product)
        Comment.counter_one(:user)

        expect { Comment.counter_one_recalculate }.to change { user.reload.comments_count }.from(1).to(0)
      end
      
      it 'should update multiple counters' do
        user = User.create
        product = Product.create(user: user)

        Comment.create(product: product)
        Comment.create(product: product, approved: true)

        Comment.has_one(:user, through: :product)
        Comment.counter_one(:user)
        Comment.counter_one(:user, column: :approved_comments_count, recalculate_scope: Comment.where(approved: true))

        expect { Comment.counter_one_recalculate }.to change { 
          user.reload.slice(:comments_count, :approved_comments_count).values 
        }.from([0, 0]).to([2, 1])
      end

      it 'should update counters with relation param' do
        user = User.create
        user_2 = User.create

        product = Product.create(user: user)
        product_2 = Product.create(user: user_2)

        Comment.create(product: product)
        Comment.create(product: product)

        Comment.create(product: product_2)

        Comment.has_one(:user, through: :product)
        Comment.counter_one(:user)

        expect { Comment.counter_one_recalculate(:user) }.to change { user.reload.comments_count }.from(0).to(2)
      end

      it 'should update counters with :recalculate_scope' do
        user = User.create
        product = Product.create(user: user)

        Comment.create(product: product)
        Comment.create(product: product, approved: true)

        Comment.has_one(:user, through: :product)
        Comment.counter_one(:user)
        Comment.counter_one(:user, column: :approved_comments_count, recalculate_scope: Comment.where(approved: true))

        expect { Comment.counter_one_recalculate }.to change { user.reload.approved_comments_count }.from(0).to(1)
      end  
    end
  end

  context 'with has_many through relation' do
    it 'should increase counter with :only option on update' do
      user = User.create
      category = Category.create
      category_1 = Category.create

      CategoryUser.create(user: user, category: category)
      CategoryUser.create(user: user, category: category_1)
      
      User.counter_one(:categories, column: :approved_users_count, only: ->(record) { record.approved? }, on: :update)

      expect { User.update(approved: true) }.to change { 
        [category.reload.approved_users_count, category_1.reload.approved_users_count]
      }.from([0, 0]).to([1, 1])
    end
  end

end
