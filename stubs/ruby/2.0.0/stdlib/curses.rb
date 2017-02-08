module Curses
def ESCDELAY=(arg0);end
def ESCDELAY();end
def TABSIZE();end
def TABSIZE=(arg0);end
def use_default_colors();end
def init_screen();end
def close_screen();end
def closed?();end
def stdscr();end
def refresh();end
def doupdate();end
def clear();end
def clrtoeol();end
def echo();end
def noecho();end
def raw();end
def noraw();end
def cbreak();end
def nocbreak();end
def crmode();end
def nocrmode();end
def nl();end
def nonl();end
def beep();end
def flash();end
def ungetch(arg0);end
def setpos(arg0, arg1);end
def standout();end
def standend();end
def inch();end
def addch(arg0);end
def insch(arg0);end
def addstr(arg0);end
def getch();end
def getstr();end
def delch();end
def deleteln();end
def insertln();end
def keyname(arg0);end
def lines();end
def cols();end
def curs_set(arg0);end
def scrl(arg0);end
def setscrreg(arg0, arg1);end
def attroff(arg0);end
def attron(arg0);end
def attrset(arg0);end
def bkgdset(arg0);end
def bkgd(arg0);end
def resizeterm(arg0, arg1);end
def resize(arg0, arg1);end
def start_color();end
def init_pair(arg0, arg1, arg2);end
def init_color(arg0, arg1, arg2, arg3);end
def has_colors?();end
def can_change_color?();end
def colors();end
def color_content(arg0);end
def color_pairs();end
def pair_content(arg0);end
def color_pair(arg0);end
def pair_number(arg0);end
def getmouse();end
def ungetmouse(arg0);end
def mouseinterval(arg0);end
def mousemask(arg0);end
def timeout=(arg0);end
def def_prog_mode();end
def reset_prog_mode();end
def self.ESCDELAY=(arg0);end
def self.ESCDELAY();end
def self.TABSIZE();end
def self.TABSIZE=(arg0);end
def self.use_default_colors();end
def self.init_screen();end
def self.close_screen();end
def self.closed?();end
def self.stdscr();end
def self.refresh();end
def self.doupdate();end
def self.clear();end
def self.clrtoeol();end
def self.echo();end
def self.noecho();end
def self.raw();end
def self.noraw();end
def self.cbreak();end
def self.nocbreak();end
def self.crmode();end
def self.nocrmode();end
def self.nl();end
def self.nonl();end
def self.beep();end
def self.flash();end
def self.ungetch(arg0);end
def self.setpos(arg0, arg1);end
def self.standout();end
def self.standend();end
def self.inch();end
def self.addch(arg0);end
def self.insch(arg0);end
def self.addstr(arg0);end
def self.getch();end
def self.getstr();end
def self.delch();end
def self.deleteln();end
def self.insertln();end
def self.keyname(arg0);end
def self.lines();end
def self.cols();end
def self.curs_set(arg0);end
def self.scrl(arg0);end
def self.setscrreg(arg0, arg1);end
def self.attroff(arg0);end
def self.attron(arg0);end
def self.attrset(arg0);end
def self.bkgdset(arg0);end
def self.bkgd(arg0);end
def self.resizeterm(arg0, arg1);end
def self.resize(arg0, arg1);end
def self.start_color();end
def self.init_pair(arg0, arg1, arg2);end
def self.init_color(arg0, arg1, arg2, arg3);end
def self.has_colors?();end
def self.can_change_color?();end
def self.colors();end
def self.color_content(arg0);end
def self.color_pairs();end
def self.pair_content(arg0);end
def self.color_pair(arg0);end
def self.pair_number(arg0);end
def self.getmouse();end
def self.ungetmouse(arg0);end
def self.mouseinterval(arg0);end
def self.mousemask(arg0);end
def self.timeout=(arg0);end
def self.def_prog_mode();end
def self.reset_prog_mode();end
end
module Curses::Key
end
class Curses::MouseEvent < Object
include Kernel
def eid();end
def x();end
def y();end
def z();end
def bstate();end
end
class Curses::Window < Data
include Kernel
def subwin(arg0, arg1, arg2, arg3);end
def close();end
def clear();end
def clrtoeol();end
def refresh();end
def noutrefresh();end
def box(*args);end
def move(arg0, arg1);end
def setpos(arg0, arg1);end
def color_set(arg0);end
def cury();end
def curx();end
def maxy();end
def maxx();end
def begy();end
def begx();end
def standout();end
def standend();end
def inch();end
def addch(arg0);end
def insch(arg0);end
def addstr(arg0);end
def <<(arg0);end
def getch();end
def getstr();end
def delch();end
def deleteln();end
def insertln();end
def scroll();end
def scrollok(arg0);end
def idlok(arg0);end
def setscrreg(arg0, arg1);end
def scrl(arg0);end
def resize(arg0, arg1);end
def keypad(arg0);end
def keypad=(arg0);end
def attroff(arg0);end
def attron(arg0);end
def attrset(arg0);end
def bkgdset(arg0);end
def bkgd(arg0);end
def getbkgd();end
def nodelay=(arg0);end
def timeout=(arg0);end
end
class Curses::Pad < Curses::Window
include Kernel
def subpad(arg0, arg1, arg2, arg3);end
def refresh(arg0, arg1, arg2, arg3, arg4, arg5);end
def noutrefresh(arg0, arg1, arg2, arg3, arg4, arg5);end
end
