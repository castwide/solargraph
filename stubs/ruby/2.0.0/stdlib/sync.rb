module Sync_m
def define_aliases(cl);end
def append_features(cl);end
def extend_object(obj);end
def self.define_aliases(cl);end
def self.append_features(cl);end
def self.extend_object(obj);end
def sync_extend();end
def sync_locked?();end
def sync_shared?();end
def sync_exclusive?();end
def sync_try_lock(*args);end
def sync_lock(*args);end
def sync_unlock(*args);end
def sync_synchronize(*args);end
def sync_mode();end
def sync_mode=(arg0);end
def sync_waiting();end
def sync_waiting=(arg0);end
def sync_upgrade_waiting();end
def sync_upgrade_waiting=(arg0);end
def sync_sh_locker();end
def sync_sh_locker=(arg0);end
def sync_ex_locker();end
def sync_ex_locker=(arg0);end
def sync_ex_count();end
def sync_ex_count=(arg0);end
def sync_inspect();end
end
class Sync_m::Err < StandardError
include Kernel
def self.Fail(*args);end
def self.exception(*args);end
def self.Fail(*args);end
end
class Sync_m::Err::UnknownLocker < Sync_m::Err
include Kernel
def self.Fail(th);end
def self.exception(*args);end
def self.Fail(th);end
end
class Sync_m::Err::LockModeFailer < Sync_m::Err
include Kernel
def self.Fail(mode);end
def self.exception(*args);end
def self.Fail(mode);end
end
module Sync_m
def define_aliases(cl);end
def append_features(cl);end
def extend_object(obj);end
def self.define_aliases(cl);end
def self.append_features(cl);end
def self.extend_object(obj);end
def sync_extend();end
def sync_locked?();end
def sync_shared?();end
def sync_exclusive?();end
def sync_try_lock(*args);end
def sync_lock(*args);end
def sync_unlock(*args);end
def sync_synchronize(*args);end
def sync_mode();end
def sync_mode=(arg0);end
def sync_waiting();end
def sync_waiting=(arg0);end
def sync_upgrade_waiting();end
def sync_upgrade_waiting=(arg0);end
def sync_sh_locker();end
def sync_sh_locker=(arg0);end
def sync_ex_locker();end
def sync_ex_locker=(arg0);end
def sync_ex_count();end
def sync_ex_count=(arg0);end
def sync_inspect();end
end
class Sync_m::Err < StandardError
include Kernel
def self.Fail(*args);end
def self.exception(*args);end
def self.Fail(*args);end
end
class Sync_m::Err::UnknownLocker < Sync_m::Err
include Kernel
def self.Fail(th);end
def self.exception(*args);end
def self.Fail(th);end
end
class Sync_m::Err::LockModeFailer < Sync_m::Err
include Kernel
def self.Fail(mode);end
def self.exception(*args);end
def self.Fail(mode);end
end
class Sync < Object
include Sync_m
include Kernel
def locked?();end
def shared?();end
def exclusive?();end
def lock(*args);end
def unlock(*args);end
def try_lock(*args);end
def synchronize(*args);end
end
class Sync_m::Err < StandardError
include Kernel
def self.Fail(*args);end
def self.exception(*args);end
def self.Fail(*args);end
end
class Sync_m::Err::UnknownLocker < Sync_m::Err
include Kernel
def self.Fail(th);end
def self.exception(*args);end
def self.Fail(th);end
end
class Sync_m::Err::LockModeFailer < Sync_m::Err
include Kernel
def self.Fail(mode);end
def self.exception(*args);end
def self.Fail(mode);end
end
class Sync < Object
include Sync_m
include Kernel
def locked?();end
def shared?();end
def exclusive?();end
def lock(*args);end
def unlock(*args);end
def try_lock(*args);end
def synchronize(*args);end
end
class Sync_m::Err < StandardError
include Kernel
def self.Fail(*args);end
def self.exception(*args);end
def self.Fail(*args);end
end
class Sync_m::Err::UnknownLocker < Sync_m::Err
include Kernel
def self.Fail(th);end
def self.exception(*args);end
def self.Fail(th);end
end
class Sync_m::Err::LockModeFailer < Sync_m::Err
include Kernel
def self.Fail(mode);end
def self.exception(*args);end
def self.Fail(mode);end
end
