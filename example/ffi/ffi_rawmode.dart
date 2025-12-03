// Ignore these lints, since these are UNIX identifiers that we're replicating
//
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

// int tcgetattr(int, struct termios *);
typedef TCGetAttrNative = Int32 Function(Int32 fildes, Pointer<TermIOS> termios);
typedef TCGetAttrDart = int Function(int fildes, Pointer<TermIOS> termios);

// int tcsetattr(int, int, const struct termios *);
typedef TCSetAttrNative = Int32 Function(Int32 fildes, Int32 optional_actions, Pointer<TermIOS> termios);
typedef TCSetAttrDart = int Function(int fildes, int optional_actions, Pointer<TermIOS> termios);

const STDIN_FILENO = 0;
const STDOUT_FILENO = 1;
const STDERR_FILENO = 2;

// INPUT FLAGS
const IGNBRK = 0x00000001; // ignore BREAK condition
const BRKINT = 0x00000002; // map BREAK to SIGINTR
const IGNPAR = 0x00000004; // ignore (discard) parity errors
const PARMRK = 0x00000008; // mark parity and framing errors
const INPCK = 0x00000010; // enable checking of parity errors
const ISTRIP = 0x00000020; // strip 8th bit off chars
const INLCR = 0x00000040; // map NL into CR
const IGNCR = 0x00000080; // ignore CR
const ICRNL = 0x00000100; // map CR to NL (ala CRMOD)
const IXON = 0x00000200; // enable output flow control
const IXOFF = 0x00000400; // enable input flow control
const IXANY = 0x00000800; // any char will restart after stop
const IMAXBEL = 0x00002000; // ring bell on input queue full
const IUTF8 = 0x00004000; // maintain state for UTF-8 VERASE

// OUTPUT FLAGS
const OPOST = 0x00000001; // enable following output processing
const ONLCR = 0x00000002; // map NL to CR-NL (ala CRMOD)
const OXTABS = 0x00000004; // expand tabs to spaces
const ONOEOT = 0x00000008; // discard EOT's (^D) on output)

// CONTROL FLAGS
const CIGNORE = 0x00000001; // ignore control flags
const CSIZE = 0x00000300; // character size mask
const CS5 = 0x00000000; // 5 bits (pseudo)
const CS6 = 0x00000100; // 6 bits
const CS7 = 0x00000200; // 7 bits
const CS8 = 0x00000300; // 8 bits

// LOCAL FLAGS
const ECHOKE = 0x00000001; // visual erase for line kill
const ECHOE = 0x00000002; // visually erase chars
const ECHOK = 0x00000004; // echo NL after line kill
const ECHO = 0x00000008; // enable echoing
const ECHONL = 0x00000010; // echo NL even if ECHO is off
const ECHOPRT = 0x00000020; // visual erase mode for hardcopy
const ECHOCTL = 0x00000040; // echo control chars as ^(Char)
const ISIG = 0x00000080; // enable signals INTR, QUIT, [D]SUSP
const ICANON = 0x00000100; // canonicalize input lines
const ALTWERASE = 0x00000200; // use alternate WERASE algorithm
const IEXTEN = 0x00000400; // enable DISCARD and LNEXT
const EXTPROC = 0x00000800; // external processing
const TOSTOP = 0x00400000; // stop background jobs from output
const FLUSHO = 0x00800000; // output being flushed (state)
const NOKERNINFO = 0x02000000; // no kernel output from VSTATUS
const PENDIN = 0x20000000; // retype pending input (state)
const NOFLSH = 0x80000000; // don't flush after interrupt

const TCSANOW = 0; // make change immediate
const TCSADRAIN = 1; // drain output, then change
const TCSAFLUSH = 2; // drain output, flush input

const VMIN = 16; // minimum number of characters to receive
const VTIME = 17; // time in 1/10s before returning

// typedef unsigned long   tcflag_t;
// typedef unsigned char   cc_t;
// typedef unsigned long   speed_t;
// #define NCCS            20

// struct termios {
// 	tcflag_t        c_iflag;        /* input flags */
// 	tcflag_t        c_oflag;        /* output flags */
// 	tcflag_t        c_cflag;        /* control flags */
// 	tcflag_t        c_lflag;        /* local flags */
// 	cc_t            c_cc[NCCS];     /* control chars */
// 	speed_t         c_ispeed;       /* input speed */
// 	speed_t         c_ospeed;       /* output speed */
// };
base class TermIOS extends Struct {
  @IntPtr()
  external int c_iflag;
  @IntPtr()
  external int c_oflag;
  @IntPtr()
  external int c_cflag;
  @IntPtr()
  external int c_lflag;

  @Array(20)
  external Array<Uint8> c_cc;

  @IntPtr()
  external int c_ispeed;
  @IntPtr()
  external int c_ospeed;
}

void main() {
  final libc = Platform.isMacOS ? DynamicLibrary.open('/usr/lib/libSystem.dylib') : DynamicLibrary.open('libc-2.28.so');

  final tcgetattr = libc.lookupFunction<TCGetAttrNative, TCGetAttrDart>('tcgetattr');
  final tcsetattr = libc.lookupFunction<TCSetAttrNative, TCSetAttrDart>('tcsetattr');

  final origTermIOS = calloc<TermIOS>();
  var result = tcgetattr(STDIN_FILENO, origTermIOS);
  print('result is $result');

  print('origTermIOS.c_iflag: 0b${origTermIOS.ref.c_iflag.toRadixString(2)}');
  print('Copying and modifying...');

  final newTermIOS = calloc<TermIOS>()
    ..ref.c_iflag = origTermIOS.ref.c_iflag & ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON)
    ..ref.c_oflag = origTermIOS.ref.c_oflag & ~OPOST
    ..ref.c_cflag = origTermIOS.ref.c_cflag | CS8
    ..ref.c_lflag = origTermIOS.ref.c_lflag & ~(ECHO | ICANON | IEXTEN | ISIG)
    ..ref.c_ispeed = origTermIOS.ref.c_ispeed
    ..ref.c_oflag = origTermIOS.ref.c_ospeed
    ..ref.c_cc = origTermIOS.ref.c_cc
    ..ref.c_cc[VMIN] = 0 // VMIN -- return each byte, or 0 for timeout
    ..ref.c_cc[VTIME] = 1; // VTIME -- 100ms timeout (unit is 1/10s)

  print('origTermIOS.c_iflag: 0b${origTermIOS.ref.c_iflag.toRadixString(2)}');
  print('newTermIOS.c_iflag:  0b${newTermIOS.ref.c_iflag.toRadixString(2)}');
  print('origTermIOS.c_oflag: 0b${origTermIOS.ref.c_oflag.toRadixString(2)}');
  print('newTermIOS.c_oflag:  0b${newTermIOS.ref.c_oflag.toRadixString(2)}');
  print('origTermIOS.c_cflag: 0b${origTermIOS.ref.c_cflag.toRadixString(2)}');
  print('newTermIOS.c_cflag:  0b${newTermIOS.ref.c_cflag.toRadixString(2)}');
  print('origTermIOS.c_lflag: 0b${origTermIOS.ref.c_lflag.toRadixString(2)}');
  print('newTermIOS.c_lflag:  0b${newTermIOS.ref.c_lflag.toRadixString(2)}');

  result = tcsetattr(STDIN_FILENO, TCSAFLUSH, newTermIOS);
  print('result is $result\n');

  print('RAW MODE: Here is some text.\nHere is some more text.');
  result = tcsetattr(STDIN_FILENO, TCSAFLUSH, origTermIOS);
  print('result is $result\n');

  print('\nORIGINAL MODE: Here is some text.\nHere is some more text.');

  calloc.free(origTermIOS);
  calloc.free(newTermIOS);
}
