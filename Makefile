APP_NAME=VoiceInput
EXECUTABLE_NAME=VoiceInput
BUILD_DIR=.build/release
APP_BUNDLE=dist/$(APP_NAME).app
MACOS_DIR=$(APP_BUNDLE)/Contents/MacOS
RESOURCES_DIR=$(APP_BUNDLE)/Contents/Resources

all: build

build:
	swift build -c release --disable-sandbox
	rm -rf $(APP_BUNDLE)
	mkdir -p $(MACOS_DIR)
	mkdir -p $(RESOURCES_DIR)
	cp $(BUILD_DIR)/$(EXECUTABLE_NAME) $(MACOS_DIR)/$(APP_NAME)
	chmod +x $(MACOS_DIR)/$(APP_NAME)
	cp Info.plist $(APP_BUNDLE)/Contents/
	echo -n "APPL????" > $(APP_BUNDLE)/Contents/PkgInfo
	codesign --force --deep --sign - $(APP_BUNDLE) || echo "Codesign failed, you may need a valid identity, but it might run anyway."

run: build
	open $(APP_BUNDLE)

clean:
	rm -rf .build
	rm -rf dist

install: build
	cp -R $(APP_BUNDLE) /Applications/
