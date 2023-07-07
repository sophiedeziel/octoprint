# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `minitest` gem.
# Please instead update this file by running `bin/tapioca gem minitest`.

# source://minitest//lib/minitest/parallel.rb#1
module Minitest
  class << self
    # source://minitest//lib/minitest.rb#173
    def __run(reporter, options); end

    # source://minitest//lib/minitest.rb#94
    def after_run(&block); end

    # source://minitest//lib/minitest.rb#66
    def autorun; end

    # source://minitest//lib/minitest.rb#19
    def backtrace_filter; end

    # source://minitest//lib/minitest.rb#19
    def backtrace_filter=(_arg0); end

    # source://minitest//lib/minitest.rb#18
    def cattr_accessor(name); end

    # source://minitest//lib/minitest.rb#1073
    def clock_time; end

    # source://minitest//lib/minitest.rb#19
    def extensions; end

    # source://minitest//lib/minitest.rb#19
    def extensions=(_arg0); end

    # source://minitest//lib/minitest.rb#264
    def filter_backtrace(bt); end

    # source://minitest//lib/minitest.rb#19
    def info_signal; end

    # source://minitest//lib/minitest.rb#19
    def info_signal=(_arg0); end

    # source://minitest//lib/minitest.rb#98
    def init_plugins(options); end

    # source://minitest//lib/minitest.rb#105
    def load_plugins; end

    # source://minitest//lib/minitest.rb#19
    def parallel_executor; end

    # source://minitest//lib/minitest.rb#19
    def parallel_executor=(_arg0); end

    # source://minitest//lib/minitest.rb#186
    def process_args(args = T.unsafe(nil)); end

    # source://minitest//lib/minitest.rb#19
    def reporter; end

    # source://minitest//lib/minitest.rb#19
    def reporter=(_arg0); end

    # source://minitest//lib/minitest.rb#140
    def run(args = T.unsafe(nil)); end

    # source://minitest//lib/minitest.rb#1064
    def run_one_method(klass, method_name); end

    # source://minitest//lib/minitest.rb#19
    def seed; end

    # source://minitest//lib/minitest.rb#19
    def seed=(_arg0); end
  end
end

# source://minitest//lib/minitest.rb#592
class Minitest::AbstractReporter
  include ::Mutex_m

  # source://mutex_m/0.1.1/mutex_m.rb#93
  def lock; end

  # source://mutex_m/0.1.1/mutex_m.rb#83
  def locked?; end

  # source://minitest//lib/minitest.rb#626
  def passed?; end

  # source://minitest//lib/minitest.rb#605
  def prerecord(klass, name); end

  # source://minitest//lib/minitest.rb#614
  def record(result); end

  # source://minitest//lib/minitest.rb#620
  def report; end

  # source://minitest//lib/minitest.rb#598
  def start; end

  # source://mutex_m/0.1.1/mutex_m.rb#78
  def synchronize(&block); end

  # source://mutex_m/0.1.1/mutex_m.rb#88
  def try_lock; end

  # source://mutex_m/0.1.1/mutex_m.rb#98
  def unlock; end
end

# source://minitest//lib/minitest.rb#909
class Minitest::Assertion < ::Exception
  # source://minitest//lib/minitest.rb#910
  def error; end

  # source://minitest//lib/minitest.rb#917
  def location; end

  # source://minitest//lib/minitest.rb#926
  def result_code; end

  # source://minitest//lib/minitest.rb#930
  def result_label; end
end

# source://minitest//lib/minitest/assertions.rb#18
module Minitest::Assertions
  # source://minitest//lib/minitest/assertions.rb#188
  def _synchronize; end

  # source://minitest//lib/minitest/assertions.rb#178
  def assert(test, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#195
  def assert_empty(obj, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#216
  def assert_equal(exp, act, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#240
  def assert_in_delta(exp, act, delta = T.unsafe(nil), msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#252
  def assert_in_epsilon(exp, act, epsilon = T.unsafe(nil), msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#259
  def assert_includes(collection, obj, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#270
  def assert_instance_of(cls, obj, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#281
  def assert_kind_of(cls, obj, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#291
  def assert_match(matcher, obj, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#303
  def assert_nil(obj, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#313
  def assert_operator(o1, op, o2 = T.unsafe(nil), msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#331
  def assert_output(stdout = T.unsafe(nil), stderr = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#355
  def assert_path_exists(path, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#374
  def assert_pattern; end

  # source://minitest//lib/minitest/assertions.rb#395
  def assert_predicate(o1, op, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#422
  def assert_raises(*exp); end

  # source://minitest//lib/minitest/assertions.rb#453
  def assert_respond_to(obj, meth, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#463
  def assert_same(exp, act, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#476
  def assert_send(send_ary, m = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#492
  def assert_silent; end

  # source://minitest//lib/minitest/assertions.rb#501
  def assert_throws(sym, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#542
  def capture_io; end

  # source://minitest//lib/minitest/assertions.rb#575
  def capture_subprocess_io; end

  # source://minitest//lib/minitest/assertions.rb#59
  def diff(exp, act); end

  # source://minitest//lib/minitest/assertions.rb#607
  def exception_details(e, msg); end

  # source://minitest//lib/minitest/assertions.rb#623
  def fail_after(y, m, d, msg); end

  # source://minitest//lib/minitest/assertions.rb#630
  def flunk(msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#638
  def message(msg = T.unsafe(nil), ending = T.unsafe(nil), &default); end

  # source://minitest//lib/minitest/assertions.rb#129
  def mu_pp(obj); end

  # source://minitest//lib/minitest/assertions.rb#152
  def mu_pp_for_diff(obj); end

  # source://minitest//lib/minitest/assertions.rb#649
  def pass(_msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#656
  def refute(test, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#664
  def refute_empty(obj, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#675
  def refute_equal(exp, act, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#687
  def refute_in_delta(exp, act, delta = T.unsafe(nil), msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#699
  def refute_in_epsilon(a, b, epsilon = T.unsafe(nil), msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#706
  def refute_includes(collection, obj, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#717
  def refute_instance_of(cls, obj, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#727
  def refute_kind_of(cls, obj, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#735
  def refute_match(matcher, obj, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#745
  def refute_nil(obj, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#780
  def refute_operator(o1, op, o2 = T.unsafe(nil), msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#789
  def refute_path_exists(path, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#762
  def refute_pattern; end

  # source://minitest//lib/minitest/assertions.rb#803
  def refute_predicate(o1, op, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#811
  def refute_respond_to(obj, meth, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#820
  def refute_same(exp, act, msg = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#833
  def skip(msg = T.unsafe(nil), bt = T.unsafe(nil)); end

  # source://minitest//lib/minitest/assertions.rb#845
  def skip_until(y, m, d, msg); end

  # source://minitest//lib/minitest/assertions.rb#854
  def skipped?; end

  # source://minitest//lib/minitest/assertions.rb#104
  def things_to_diff(exp, act); end

  class << self
    # source://minitest//lib/minitest/assertions.rb#29
    def diff; end

    # source://minitest//lib/minitest/assertions.rb#47
    def diff=(o); end
  end
end

# source://minitest//lib/minitest/assertions.rb#201
Minitest::Assertions::E = T.let(T.unsafe(nil), String)

# source://minitest//lib/minitest/assertions.rb#19
Minitest::Assertions::UNDEFINED = T.let(T.unsafe(nil), Object)

# source://minitest//lib/minitest.rb#1041
class Minitest::BacktraceFilter
  # source://minitest//lib/minitest.rb#1049
  def filter(bt); end
end

# source://minitest//lib/minitest.rb#1043
Minitest::BacktraceFilter::MT_RE = T.let(T.unsafe(nil), Regexp)

# source://minitest//lib/minitest.rb#860
class Minitest::CompositeReporter < ::Minitest::AbstractReporter
  # source://minitest//lib/minitest.rb#864
  def initialize(*reporters); end

  # source://minitest//lib/minitest.rb#876
  def <<(reporter); end

  # source://minitest//lib/minitest.rb#869
  def io; end

  # source://minitest//lib/minitest.rb#880
  def passed?; end

  # source://minitest//lib/minitest.rb#888
  def prerecord(klass, name); end

  # source://minitest//lib/minitest.rb#895
  def record(result); end

  # source://minitest//lib/minitest.rb#901
  def report; end

  # source://minitest//lib/minitest.rb#862
  def reporters; end

  # source://minitest//lib/minitest.rb#862
  def reporters=(_arg0); end

  # source://minitest//lib/minitest.rb#884
  def start; end
end

# source://minitest//lib/minitest.rb#985
module Minitest::Guard
  # source://minitest//lib/minitest.rb#990
  def jruby?(platform = T.unsafe(nil)); end

  # source://minitest//lib/minitest.rb#997
  def maglev?(platform = T.unsafe(nil)); end

  # source://minitest//lib/minitest.rb#1007
  def mri?(platform = T.unsafe(nil)); end

  # source://minitest//lib/minitest.rb#1014
  def osx?(platform = T.unsafe(nil)); end

  # source://minitest//lib/minitest.rb#1021
  def rubinius?(platform = T.unsafe(nil)); end

  # source://minitest//lib/minitest.rb#1031
  def windows?(platform = T.unsafe(nil)); end
end

# source://minitest//lib/minitest/parallel.rb#2
module Minitest::Parallel; end

# source://minitest//lib/minitest/parallel.rb#7
class Minitest::Parallel::Executor
  # source://minitest//lib/minitest/parallel.rb#17
  def initialize(size); end

  # source://minitest//lib/minitest/parallel.rb#43
  def <<(work); end

  # source://minitest//lib/minitest/parallel.rb#50
  def shutdown; end

  # source://minitest//lib/minitest/parallel.rb#12
  def size; end

  # source://minitest//lib/minitest/parallel.rb#26
  def start; end
end

# source://minitest//lib/minitest/parallel.rb#56
module Minitest::Parallel::Test
  # source://minitest//lib/minitest/parallel.rb#57
  def _synchronize; end
end

# source://minitest//lib/minitest/parallel.rb#59
module Minitest::Parallel::Test::ClassMethods
  # source://minitest//lib/minitest/parallel.rb#60
  def run_one_method(klass, method_name, reporter); end

  # source://minitest//lib/minitest/parallel.rb#64
  def test_order; end
end

# source://minitest//lib/minitest.rb#657
class Minitest::ProgressReporter < ::Minitest::Reporter
  # source://minitest//lib/minitest.rb#658
  def prerecord(klass, name); end

  # source://minitest//lib/minitest.rb#665
  def record(result); end
end

# source://minitest//lib/minitest.rb#489
module Minitest::Reportable
  # source://minitest//lib/minitest.rb#509
  def class_name; end

  # source://minitest//lib/minitest.rb#530
  def error?; end

  # source://minitest//lib/minitest.rb#504
  def location; end

  # source://minitest//lib/minitest.rb#496
  def passed?; end

  # source://minitest//lib/minitest.rb#516
  def result_code; end

  # source://minitest//lib/minitest.rb#523
  def skipped?; end
end

# source://minitest//lib/minitest.rb#633
class Minitest::Reporter < ::Minitest::AbstractReporter
  # source://minitest//lib/minitest.rb#642
  def initialize(io = T.unsafe(nil), options = T.unsafe(nil)); end

  # source://minitest//lib/minitest.rb#635
  def io; end

  # source://minitest//lib/minitest.rb#635
  def io=(_arg0); end

  # source://minitest//lib/minitest.rb#640
  def options; end

  # source://minitest//lib/minitest.rb#640
  def options=(_arg0); end
end

# source://minitest//lib/minitest.rb#542
class Minitest::Result < ::Minitest::Runnable
  include ::Minitest::Reportable

  # source://minitest//lib/minitest.rb#575
  def class_name; end

  # source://minitest//lib/minitest.rb#551
  def klass; end

  # source://minitest//lib/minitest.rb#551
  def klass=(_arg0); end

  # source://minitest//lib/minitest.rb#556
  def source_location; end

  # source://minitest//lib/minitest.rb#556
  def source_location=(_arg0); end

  # source://minitest//lib/minitest.rb#579
  def to_s; end

  class << self
    # source://minitest//lib/minitest.rb#561
    def from(runnable); end
  end
end

# source://minitest//lib/minitest.rb#277
class Minitest::Runnable
  # source://minitest//lib/minitest.rb#445
  def initialize(name); end

  # source://minitest//lib/minitest.rb#281
  def assertions; end

  # source://minitest//lib/minitest.rb#281
  def assertions=(_arg0); end

  # source://minitest//lib/minitest.rb#441
  def failure; end

  # source://minitest//lib/minitest.rb#286
  def failures; end

  # source://minitest//lib/minitest.rb#286
  def failures=(_arg0); end

  # source://minitest//lib/minitest.rb#427
  def marshal_dump; end

  # source://minitest//lib/minitest.rb#437
  def marshal_load(ary); end

  # source://minitest//lib/minitest.rb#304
  def name; end

  # source://minitest//lib/minitest.rb#311
  def name=(o); end

  # source://minitest//lib/minitest.rb#464
  def passed?; end

  # source://minitest//lib/minitest.rb#473
  def result_code; end

  # source://minitest//lib/minitest.rb#454
  def run; end

  # source://minitest//lib/minitest.rb#480
  def skipped?; end

  # source://minitest//lib/minitest.rb#291
  def time; end

  # source://minitest//lib/minitest.rb#291
  def time=(_arg0); end

  # source://minitest//lib/minitest.rb#293
  def time_it; end

  class << self
    # source://minitest//lib/minitest.rb#1083
    def inherited(klass); end

    # source://minitest//lib/minitest.rb#318
    def methods_matching(re); end

    # source://minitest//lib/minitest.rb#397
    def on_signal(name, action); end

    # source://minitest//lib/minitest.rb#322
    def reset; end

    # source://minitest//lib/minitest.rb#333
    def run(reporter, options = T.unsafe(nil)); end

    # source://minitest//lib/minitest.rb#369
    def run_one_method(klass, method_name, reporter); end

    # source://minitest//lib/minitest.rb#414
    def runnable_methods; end

    # source://minitest//lib/minitest.rb#421
    def runnables; end

    # source://minitest//lib/minitest.rb#378
    def test_order; end

    # source://minitest//lib/minitest.rb#382
    def with_info_handler(reporter, &block); end
  end
end

# source://minitest//lib/minitest.rb#395
Minitest::Runnable::SIGNALS = T.let(T.unsafe(nil), Hash)

# source://minitest//lib/minitest.rb#938
class Minitest::Skip < ::Minitest::Assertion
  # source://minitest//lib/minitest.rb#939
  def result_label; end
end

# source://minitest//lib/minitest.rb#695
class Minitest::StatisticsReporter < ::Minitest::Reporter
  # source://minitest//lib/minitest.rb#737
  def initialize(io = T.unsafe(nil), options = T.unsafe(nil)); end

  # source://minitest//lib/minitest.rb#697
  def assertions; end

  # source://minitest//lib/minitest.rb#697
  def assertions=(_arg0); end

  # source://minitest//lib/minitest.rb#702
  def count; end

  # source://minitest//lib/minitest.rb#702
  def count=(_arg0); end

  # source://minitest//lib/minitest.rb#730
  def errors; end

  # source://minitest//lib/minitest.rb#730
  def errors=(_arg0); end

  # source://minitest//lib/minitest.rb#725
  def failures; end

  # source://minitest//lib/minitest.rb#725
  def failures=(_arg0); end

  # source://minitest//lib/minitest.rb#750
  def passed?; end

  # source://minitest//lib/minitest.rb#758
  def record(result); end

  # source://minitest//lib/minitest.rb#768
  def report; end

  # source://minitest//lib/minitest.rb#707
  def results; end

  # source://minitest//lib/minitest.rb#707
  def results=(_arg0); end

  # source://minitest//lib/minitest.rb#735
  def skips; end

  # source://minitest//lib/minitest.rb#735
  def skips=(_arg0); end

  # source://minitest//lib/minitest.rb#754
  def start; end

  # source://minitest//lib/minitest.rb#714
  def start_time; end

  # source://minitest//lib/minitest.rb#714
  def start_time=(_arg0); end

  # source://minitest//lib/minitest.rb#720
  def total_time; end

  # source://minitest//lib/minitest.rb#720
  def total_time=(_arg0); end
end

# source://minitest//lib/minitest.rb#789
class Minitest::SummaryReporter < ::Minitest::StatisticsReporter
  # source://minitest//lib/minitest.rb#823
  def aggregated_results(io); end

  # source://minitest//lib/minitest.rb#791
  def old_sync; end

  # source://minitest//lib/minitest.rb#791
  def old_sync=(_arg0); end

  # source://minitest//lib/minitest.rb#806
  def report; end

  # source://minitest//lib/minitest.rb#794
  def start; end

  # source://minitest//lib/minitest.rb#818
  def statistics; end

  # source://minitest//lib/minitest.rb#843
  def summary; end

  # source://minitest//lib/minitest.rb#790
  def sync; end

  # source://minitest//lib/minitest.rb#790
  def sync=(_arg0); end

  # source://minitest//lib/minitest.rb#839
  def to_s; end
end

# source://minitest//lib/minitest/test.rb#10
class Minitest::Test < ::Minitest::Runnable
  include ::Minitest::Assertions
  include ::Minitest::Reportable
  include ::Minitest::Test::LifecycleHooks
  include ::Minitest::Guard
  extend ::Minitest::Guard

  # source://minitest//lib/minitest/test.rb#190
  def capture_exceptions; end

  # source://minitest//lib/minitest/test.rb#15
  def class_name; end

  # source://minitest//lib/minitest/test.rb#207
  def neuter_exception(e); end

  # source://minitest//lib/minitest/test.rb#218
  def new_exception(klass, msg, bt, kill = T.unsafe(nil)); end

  # source://minitest//lib/minitest/test.rb#86
  def run; end

  # source://minitest//lib/minitest/test.rb#200
  def sanitize_exception(e); end

  # source://minitest//lib/minitest/test.rb#232
  def with_info_handler(&block); end

  class << self
    # source://minitest//lib/minitest/test.rb#35
    def i_suck_and_my_tests_are_order_dependent!; end

    # source://minitest//lib/minitest/test.rb#26
    def io_lock; end

    # source://minitest//lib/minitest/test.rb#26
    def io_lock=(_arg0); end

    # source://minitest//lib/minitest/test.rb#48
    def make_my_diffs_pretty!; end

    # source://minitest//lib/minitest/test.rb#59
    def parallelize_me!; end

    # source://minitest//lib/minitest/test.rb#69
    def runnable_methods; end
  end
end

# source://minitest//lib/minitest/test.rb#113
module Minitest::Test::LifecycleHooks
  # source://minitest//lib/minitest/test.rb#163
  def after_setup; end

  # source://minitest//lib/minitest/test.rb#187
  def after_teardown; end

  # source://minitest//lib/minitest/test.rb#148
  def before_setup; end

  # source://minitest//lib/minitest/test.rb#172
  def before_teardown; end

  # source://minitest//lib/minitest/test.rb#154
  def setup; end

  # source://minitest//lib/minitest/test.rb#178
  def teardown; end
end

# source://minitest//lib/minitest/test.rb#19
Minitest::Test::PASSTHROUGH_EXCEPTIONS = T.let(T.unsafe(nil), Array)

# source://minitest//lib/minitest/test.rb#21
Minitest::Test::SETUP_METHODS = T.let(T.unsafe(nil), Array)

# source://minitest//lib/minitest/test.rb#23
Minitest::Test::TEARDOWN_METHODS = T.let(T.unsafe(nil), Array)

# source://minitest//lib/minitest.rb#948
class Minitest::UnexpectedError < ::Minitest::Assertion
  # source://minitest//lib/minitest.rb#951
  def initialize(error); end

  # source://minitest//lib/minitest.rb#956
  def backtrace; end

  # source://minitest//lib/minitest.rb#949
  def error; end

  # source://minitest//lib/minitest.rb#949
  def error=(_arg0); end

  # source://minitest//lib/minitest.rb#960
  def message; end

  # source://minitest//lib/minitest.rb#965
  def result_label; end
end

# source://minitest//lib/minitest/unit.rb#20
class Minitest::Unit
  class << self
    # source://minitest//lib/minitest/unit.rb#36
    def after_tests(&b); end

    # source://minitest//lib/minitest/unit.rb#30
    def autorun; end
  end
end

# source://minitest//lib/minitest/unit.rb#22
class Minitest::Unit::TestCase < ::Minitest::Test
  class << self
    # source://minitest//lib/minitest/unit.rb#23
    def inherited(klass); end
  end
end

# source://minitest//lib/minitest/unit.rb#21
Minitest::Unit::VERSION = T.let(T.unsafe(nil), String)

# source://minitest//lib/minitest.rb#12
Minitest::VERSION = T.let(T.unsafe(nil), String)
