module Observable
def add_observer(observer, func = nil);end
def delete_observer(observer);end
def delete_observers();end
def count_observers();end
def changed(*args);end
def changed?();end
def notify_observers(*args);end
end
