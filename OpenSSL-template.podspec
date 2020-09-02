Pod::Spec.new do |s|
  s.platform		= :osx, "10.12"
  s.name            = "OpenSSL-OSX"
  s.version         = "1.0.211"
  s.summary         = "OpenSSL is an SSL/TLS and Crypto toolkit. Deprecated in OS X, this CocoaPod will add the latest OpenSSL to your OS X project."
  s.author          = "OpenSSL Project <openssl-dev@openssl.org>"

  s.homepage        = "https://github.com/GerTeunis/OpenSSL-OSX-Pod"
  s.license         = 'BSD-style Open Source'
  s.source          = { :http => "https://www.openssl.org/source/openssl-1.0.2j.tar.gz", :sha1 => "bdfbdb416942f666865fa48fe13c2d0e588df54f"}
  s.source_files    = "opensslIncludes/openssl/*.h"
  s.header_dir      = "openssl"
  s.license	        = { :type => 'OpenSSL (OpenSSL/SSLeay)', :file => 'LICENSE' }

  s.prepare_command = <<-CMD
    VERSION="1.0.2j"
    SDKVERSION=`xcrun --sdk macosx --show-sdk-version 2> /dev/null`
    SDKPATH=`xcrun --sdk macosx --show-sdk-path 2> /dev/null`
    MIN_SDK_VERSION="10.12"

    BASEPATH="${PWD}"
    CURRENTPATH="${TMPDIR}/openssl"
    ARCHS="x86_64"
    DEVELOPER=`xcode-select -print-path`
    PLATFORM="MacOSX"

    mkdir -p "${CURRENTPATH}"
    mkdir -p "${CURRENTPATH}/bin"

    curl -L "https://www.openssl.org/source/openssl-${VERSION}.tar.gz" -o file.tgz
    cp "file.tgz" "${CURRENTPATH}/file.tgz"
    cd "${CURRENTPATH}"
    tar -xzf file.tgz
    cd "openssl-${VERSION}"

    for ARCH in ${ARCHS}
    do

      if [ "${ARCH}" == "i386" ];
      then
          CONFIGURE_FOR="darwin-i386-cc"
      elif [ "${ARCH}" == "x86_64" ];
      then
			    CONFIGURE_FOR="darwin64-x86_64-cc"
      fi

      echo "Building openssl-${VERSION} for ${PLATFORM} ${SDKVERSION} ${ARCH}"
      echo "Please stand by..."

      export CC="${DEVELOPER}/usr/bin/gcc -arch ${ARCH} -mmacosx-version-min=${MIN_SDK_VERSION}"
      mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
      LOG="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/build-openssl-${VERSION}.log"

      LIPO_LIBSSL="${LIPO_LIBSSL} ${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/lib/libssl.a"
      LIPO_LIBCRYPTO="${LIPO_LIBCRYPTO} ${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/lib/libcrypto.a"

      ./Configure ${CONFIGURE_FOR} --openssldir="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" > "${LOG}" 2>&1
      sed -ie "s!^CFLAG=!CFLAG=-isysroot ${SDKPATH} !" "Makefile"

      make >> "${LOG}" 2>&1
      make all install_sw >> "${LOG}" 2>&1
      make clean >> "${LOG}" 2>&1
    done


    echo "Build library..."
    rm -rf "${BASEPATH}/lib/"
    mkdir -p "${BASEPATH}/lib/"
    lipo -create ${LIPO_LIBSSL}    -output "${BASEPATH}/lib/libssl.a"
    lipo -create ${LIPO_LIBCRYPTO} -output "${BASEPATH}/lib/libcrypto.a"

    echo "Copying headers..."
    rm -rf "${BASEPATH}/opensslIncludes/"
    mkdir -p "${BASEPATH}/opensslIncludes/"
    cp -RL "${CURRENTPATH}/openssl-${VERSION}/include/openssl" "${BASEPATH}/opensslIncludes/"

    cd "${BASEPATH}"
    echo "Building done."

    echo "Cleaning up..."
    rm -rf "${CURRENTPATH}"
    echo "Done."
  CMD

  s.public_header_files = "opensslIncludes/openssl/*.h"
  s.vendored_libraries  = "lib/libcrypto.a", "lib/libssl.a"

  s.libraries             = 'crypto', 'ssl'
  s.requires_arc          = false

end
