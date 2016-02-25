#!/bin/bash
declare -x DEV="ACKApi.o"
declare -x TAG="something.o"

declare -x SDK="libACKSDK.a"

# deal with platform armv7 
mkdir armv7
lipo libarm64v7.a -thin armv7 -output armv7/libarmv7.a
ar -t armv7/libarmv7.a
cd armv7 && ar xv libarmv7.a
#rm $divide
cd .. && ar rcs armv7.a armv7/$DEV

# deal with platform arm64
mkdir arm64
lipo libarm64v7.a -thin arm64 -output arm64/libarm64.a
ar -t arm64/libarm64.a
cd arm64 && ar xv libarm64.a
#rm $divide
cd .. && ar rcs arm64.a arm64/$DEV

# deal with platform i386
mkdir i386
cp -R libi386.a i386/
#lipo libi386.a -thin i386 -output arm64/libarm64.a
ar -t i386/libi386.a
cd i386 && ar xv libi386.a
#rm $divide
cd .. && ar rcs i386.a i386/$DEV

# deal with platform x66_64
mkdir x86
cp -R libx86.a x86/
#lipo libarm64v7.a -thin arm64 -output arm64/libarm64.a
ar -t x86/libx86.a
cd x86 && ar xv libx86.a
#rm $divide
cd .. && ar rcs x86.a x86/$DEV

#union the sdks
lipo -create arm64.a armv7.a i386.a x86.a -output $SDK

unset DEV
unset SDK