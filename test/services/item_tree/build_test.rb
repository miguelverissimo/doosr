# test/services/item_tree/build_test.rb
require "test_helper"

class ItemTreeBuildTest < ActiveSupport::TestCase
  # Helpers --------------------------------------------------------------

  # From Rails's ActiveSupport::TestCase, for N+1 query detection.
  def assert_queries(n = nil, options = {}, &block) # :doc: Rails.env.test?
    result = count_queries(&block)
    if n.is_a?(Range)
      assert_includes n, result, "Expected to run between #{n.first} and #{n.last} queries, but ran #{result}"
    else
      assert_equal n, result, "Expected to run #{n} queries, but ran #{result}"
    end
  end

  def count_queries(&block)
    count = 0
    counter = ->(_name, _started, _finished, _unique_id, payload) {
      unless ['CACHE', 'SCHEMA'].include?(payload[:name])
        count += 1
      end
    }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end

  def current_user
    @current_user ||= User.create!(email: "test@example.com", password: "password123")
  end

  def tnode(label:, children: [])
    { label: label, children: children }
  end

  def to_label_hash(node)
    {
      label: node.label,
      children: node.children.map { |c| to_label_hash(c) }
    }
  end

  def find_label(node, label)
    return node if node.label == label
    node.children.each do |child|
      found = find_label(child, label)
      return found if found
    end
    nil
  end

  def create_item!(title)
    Item.create!(title: title, user: current_user, item_type: :section, state: :todo)
  end

  def create_descendant_for!(descendable:, active: [], inactive: [])
    desc = descendable.descendant || Descendant.create!(descendable: descendable)
    desc.update!(active_items: active, inactive_items: inactive)
    desc
  end

  # If your Descendant doesn't require descendable (e.g. root is stand-alone),
  # create a root owner model or allow descendable to be nil.
  # For this test suite, we assume Descendant can exist without a descendable.
  def create_root_descendant!(descendable: nil, active: [], inactive: [])
    descendable ||= create_item!('root')
    desc = descendable.descendant || Descendant.create!(descendable: descendable)
    desc.update!(active_items: active, inactive_items: inactive)
    desc
  end

  # Tests ---------------------------------------------------------------

  test "builds the full example tree with active items first then inactive, recursively" do
    root_desc = create_root_descendant!

    foo = create_item!("foo")
    create_descendant_for!(descendable: foo) # foo.descendant exists

    root_desc.update!(active_items: [foo.id], inactive_items: [])

    # foo descendant: active [bar, baz], inactive [qux]
    bar = create_item!("bar")
    baz = create_item!("baz")
    qux = create_item!("qux")

    create_descendant_for!(descendable: bar)
    create_descendant_for!(descendable: baz)

    foo.descendant.update!(
      active_items: [bar.id, baz.id],
      inactive_items: [qux.id]
    )

    # bar descendant: active [bar 1], inactive [bar 2]
    bar1 = create_item!("bar 1")
    bar2 = create_item!("bar 2")
    bar.descendant.update!(active_items: [bar1.id], inactive_items: [bar2.id])

    # baz descendant: active [baz 1, baz 2], inactive [baz 3, baz 4]
    baz1 = create_item!("baz 1")
    baz2 = create_item!("baz 2")
    baz3 = create_item!("baz 3")
    baz4 = create_item!("baz 4")
    create_descendant_for!(descendable: baz2)

    baz.descendant.update!(
      active_items: [baz1.id, baz2.id],
      inactive_items: [baz3.id, baz4.id]
    )

    # baz 2 descendant: active [baz 2.2], inactive [baz 2.1]
    baz22 = create_item!("baz 2.2")
    baz21 = create_item!("baz 2.1")
    baz2.descendant.update!(active_items: [baz22.id], inactive_items: [baz21.id])

    tree = ItemTree::Build.call(root_desc)

    expected = tnode(
      label: "root",
      children: [
        tnode(
          label: "foo",
          children: [
            tnode(label: "bar", children: [tnode(label: "bar 1"), tnode(label: "bar 2")]),
            tnode(
              label: "baz",
              children: [
                tnode(label: "baz 1"),
                tnode(label: "baz 2", children: [tnode(label: "baz 2.2"), tnode(label: "baz 2.1")]),
                tnode(label: "baz 3"),
                tnode(label: "baz 4")
              ]
            ),
            tnode(label: "qux")
          ]
        )
      ]
    )

    assert_equal expected, to_label_hash(tree)
  end

  test "preserves ordering: active ids first (in their order), then inactive ids (in their order)" do
    root_desc = create_root_descendant!

    a = create_item!("a")
    b = create_item!("b")
    c = create_item!("c")
    d = create_item!("d")

    # give them descendants so includes(:descendant) has something to load, not required though
    [a, b, c, d].each { |it| create_descendant_for!(descendable: it) }

    root_desc.update!(active_items: [c.id, a.id], inactive_items: [d.id, b.id])

    tree = ItemTree::Build.call(root_desc)
    labels = tree.children.map(&:label)

    assert_equal %w[c a d b], labels
  end

  test "returns an empty root children list when root descendant is nil" do
    tree = ItemTree::Build.call(nil)
    assert_equal "root", tree.label
    assert_equal [], tree.children
  end

  test "handles empty arrays (no children)" do
    root_desc = create_root_descendant!(active: [], inactive: [])
    tree = ItemTree::Build.call(root_desc)
    assert_equal [], tree.children
  end

  test "skips stale item ids instead of raising" do
    root_desc = create_root_descendant!
    real = create_item!("real")
    create_descendant_for!(descendable: real)

    missing_id = 999_999_999

    root_desc.update!(active_items: [missing_id, real.id], inactive_items: [missing_id])

    tree = ItemTree::Build.call(root_desc)
    assert_equal ["real"], tree.children.map(&:label)
  end

  test "cycle detection: if a descendant appears again in the current path, inserts a sentinel and stops" do
    root_desc = create_root_descendant!
    foo = create_item!("foo")

    # Make foo.descendant point to a descendant that (incorrectly) references foo again.
    foo_desc = create_descendant_for!(descendable: foo)

    root_desc.update!(active_items: [foo.id], inactive_items: [])

    # Create a cycle: foo_desc lists foo again (bad data), so recursion sees foo -> foo_desc -> foo -> foo_desc ...
    foo_desc.update!(active_items: [foo.id], inactive_items: [])

    tree = ItemTree::Build.call(root_desc.reload)
    foo_node = find_label(tree, "foo")
    assert foo_node, "expected to find foo node"

    # Under foo, we should see "(cycle detected)" and not infinite recursion.
    assert_includes foo_node.children.map(&:label), "(cycle detected)"
  end

  # Optional: query-count smoke test (can be brittle across Rails versions/adapters).
  # Enable only if you want to enforce "not exploding into N+1".
  #
  test "does not explode into N+1 queries for descendants" do
    root_desc = create_root_descendant!
    items = 10.times.map { |i| create_item!("it#{i}") }
    items.each { |it| create_descendant_for!(descendable: it) }
    root_desc.update!(active_items: items.map(&:id), inactive_items: [])
  
    assert_queries(2..6) do
      ItemTree::Build.call(root_desc)
    end
  end
end