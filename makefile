# Copyright (c) 2009-2010 Satoshi Nakamoto
# Distributed under the MIT/X11 software license, see the accompanying
# file license.txt or http://www.opensource.org/licenses/mit-license.php.

CXX=g++

WXINCLUDEPATHS=$(shell wx-config --cxxflags)

WXLIBS=$(shell wx-config --libs)

# for boost 1.37, add -mt to the boost libraries
LIBS= \
 -Wl,-Bstatic \
   -l boost_system \
   -l boost_filesystem \
   -l boost_program_options \
   -l boost_thread \
   -l db_cxx \
   -l ssl \
   -l crypto \
 -Wl,-Bdynamic \
   -l gthread-2.0 \
   -l z \
   -l dl

DEFS=-DNOPCH -DFOURWAYSSE2 -DUSE_SSL
DEBUGFLAGS=-g -D__WXDEBUG__
CXXFLAGS=-O0 -Wno-invalid-offsetof -Wformat $(DEBUGFLAGS) $(DEFS)
HEADERS=headers.h strlcpy.h serialize.h uint256.h util.h key.h bignum.h base58.h \
    script.h db.h net.h irc.h main.h rpc.h uibase.h ui.h noui.h init.h \
    hook.h

BASE_OBJS = \
    obj/util.o \
    obj/script.o \
    obj/db.o \
    obj/net.o \
    obj/irc.o \
    obj/main.o \
    obj/rpc.o \
    obj/init.o \
    cryptopp/obj/sha.o \
    cryptopp/obj/cpu.o

OBJS= \
      $(BASE_OBJS) \
      hook.o

all: namecoind


obj/%.o: %.cpp $(HEADERS)
	$(CXX) -c $(CXXFLAGS) $(WXINCLUDEPATHS) -DGUI -o $@ $<

cryptopp/obj/%.o: cryptopp/%.cpp
	$(CXX) -c $(CXXFLAGS) -O3 -o $@ $<

obj/sha256.o: sha256.cpp
	$(CXX) -c $(CXXFLAGS) -msse2 -O3 -march=amdfam10 -o $@ $<

bitcoin: $(OBJS) obj/ui.o obj/uibase.o obj/sha256.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(WXLIBS) $(LIBS)


obj/nogui/%.o: %.cpp $(HEADERS)
	$(CXX) -c $(CXXFLAGS) -o $@ $<

bitcoind: $(OBJS:obj/%=obj/nogui/%) obj/sha256.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)

obj/nogui/namecoin.o: namecoin.h
namecoind: $(BASE_OBJS:obj/%=obj/nogui/%) obj/sha256.o obj/nogui/namecoin.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)

tests: $(BASE_OBJS:obj/%=obj/nogui/%) obj/sha256.o obj/nogui/tests.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)

clean:
	-rm -f obj/*.o
	-rm -f obj/nogui/*.o
	-rm -f cryptopp/obj/*.o
	-rm -f headers.h.gch
	-rm -f bitcoin
	-rm -f bitcoind
