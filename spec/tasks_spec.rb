require 'spec_helper'

describe DO::Tasks do

  def cmd; DO::Tasks; end

  before(:each){ cmd.tasks.clear }

  it 'should init a basic task' do
    DO::Commands.load_recipes
    task = cmd.task(:name){}
    task[:name].should == 'name'
    task[:desc].should == ''
    task[:namespace].should == ''
    task[:block] == nil
    cmd.tasks.size.should == 1
  end

  it 'should clear old task' do
    cmd.tasks.size.should == 0
  end

  it 'should have description' do
    cmd.desc :desc
    task = cmd.task(:name){}
    task[:desc].should == 'desc'
  end

  it 'should not confuse desc' do
    cmd.desc :desc
    task = cmd.task(:name){}
    task[:desc].should == 'desc'
    task = cmd.task(:name_alt){}
    task[:desc].should == ''
  end

  it 'should have namespace' do
    cmd.tasks.clear
    @a = 0
    cmd.namespace :namespace do
      cmd.task(:one){ @a+=1 }
      cmd.task(:two){ @a+=1 }
    end
    cmd.task(:three){ @a+=1 }
    cmd.tasks.should have(3).items
    @a.should == 0
    cmd.tasks.each { |t| t[:block].call }
    @a.should == 3
    cmd.tasks[0][:namespace].should == 'namespace'
    cmd.tasks[1][:namespace].should == 'namespace'
    cmd.tasks[2][:namespace].should == ''
  end

  it 'should have nested namespaces' do
    cmd.namespace :foo do
      cmd.task(:one)
      cmd.namespace :bar do
        cmd.task(:two)
        cmd.namespace :bax do
          cmd.task(:three)
        end
      end
      cmd.task(:four)
    end
    cmd.task(:five)
    cmd.tasks[0][:namespace].should == 'foo'
    cmd.tasks[1][:namespace].should == 'foo:bar'
    cmd.tasks[2][:namespace].should == 'foo:bar:bax'
    cmd.tasks[3][:namespace].should == 'foo'
    cmd.tasks[4][:namespace].should == ''
  end

  it 'should raise notfound' do
    expect { cmd.task_run(:foobar) }.to raise_error(DO::Tasks::NotFound)
  end

  it 'should have a dependency flag' do
    cmd.task(:foo) { |o| o[:dependency].should be_true }
    cmd.task(:bar => :foo) { |o| o.should_not have_key(:dependency) }
    cmd.task_run(:bar)
  end

  context 'when using #task_run' do
    it 'should run correctly' do
      cmd.namespace :foo do
        cmd.task(:one){@a=1}
        cmd.namespace :bar do
          cmd.task(:two){@b=2}
        end
        cmd.task(:three){@c=3}
      end
      cmd.task(:four){@d=4}
      cmd.task_run('foo:one'); @a.should == 1
      cmd.task_run('foo:bar:two'); @b.should == 2
      cmd.task_run('foo:three'); @c.should == 3
      cmd.task_run('four'); @d.should == 4
    end

    it 'should parse options' do
      cmd.namespace :foo do
        cmd.task(:one){ |o| @o=o }
        cmd.namespace :bar do
          cmd.task(:two){ |o| @o=o }
        end
        cmd.task(:three){ |o| @o=o }
      end
      cmd.task(:four){ |o| @o=o }
      cmd.task_run('foo:one', '--name=mine'); @o[:name].should == 'mine'
      cmd.task_run('foo:bar:two', '--age=2'); @o[:age].should == 2
      cmd.task_run('foo:three', '--yes'); @o[:yes].should == true
      cmd.task_run('four', '--no-value'); @o[:value].should == false
    end

    it 'should run deps' do
      cmd.task(:dep1){@deps=1}
      cmd.task(:last => [:dep1]){@deps}
      cmd.task_run(:last) == 1
    end

    it 'should share with opts with deps' do
      cmd.task(:dep1){ |d| @value = d[:value] }
      cmd.task(:dep2){ |d| @value+=1 }
      cmd.task(:dep3){ |d| @value+=1 }
      cmd.task(:last => [:dep1, :dep2, :dep3]){ |d| @value+=1 }
      cmd.task_run(:last, '--value=5')
      @value.should == 8
    end

    it 'should repeat itself with blocks' do
      cmd.task(:dep1){ |b| @value=3; b.call }
      cmd.task(:last, :in => :dep1){ @value+=1 }
      cmd.task_run(:last)
      @value.should == 4
    end

    it 'should repeat itself without blocks' do
      cmd.tasks.clear
      cmd.task(:dep1) { @value  = 5 }
      cmd.task(:dep2) { @value += 1 }
      cmd.task(:dep3) { @value += 1 }
      cmd.task(:dep4) { @value += 1 }
      cmd.task(:last, :in => [:dep1, :dep2, :dep3, :dep4])
      cmd.task_run(:last)
      @value.should == 8
    end

    it 'should run methods if NotFound raised' do
      cmd.tasks.clear
      cmd.send(:define_method, :demos) {}
      cmd.task(:demo => :demos)
      expect { cmd.task_run(:demo) }.to_not raise_error
    end

    it 'should resolve dependency namespace' do
      cmd.tasks.clear
      cmd.namespace :ns do
        cmd.task(:foo){@a=1}
        cmd.task(:bar => :foo){ @a.should == 1 }
      end
      cmd.run_task('ns:bar')
    end
  end
end
