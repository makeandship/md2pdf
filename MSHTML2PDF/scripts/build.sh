xcodebuild CONFIGURATION_BUILD_DIR="$PWD"\
  -workspace '../html2pdf.xcworkspace' \
  -scheme 'html2pdf' \
  -configuration 'Release'
rm ../../html2pdf
mv html2pdf ../../html2pdf
chmod +x ../../html2pdf
xcodebuild CONFIGURATION_BUILD_DIR="$PWD"\
  -workspace '../html2pdf.xcworkspace' \
  -scheme 'html2pdf' \
  -configuration 'Release' \
  clean
