.PHONY: default
default:
	@echo "No target specified. Please use 'make <target>' to run a specific task."

.PHONY: clean
clean:
	@echo "cleaning Rive download markers.."
	@ [ ! -e ios/rive_marker_ios_setup_complete ] || rm ios/rive_marker_ios_setup_complete
	@ [ ! -e ios/rive_marker_ios_development ] || rm ios/rive_marker_ios_development
	@ [ ! -e macos/rive_marker_macos_setup_complete ] || rm macos/rive_marker_macos_setup_complete
	@ [ ! -e macos/rive_marker_macos_development ] || rm macos/rive_marker_macos_development
	@ [ ! -e windows/rive_marker_windows_development ] || rm windows/rive_marker_windows_development
	@ [ ! -e windows/rive_marker_windows_setup_complete ] || rm windows/rive_marker_windows_setup_complete
	@echo "clean complete"


.PHONY: update_cpp_runtime
update_cpp_runtime:
	@rsync -av --exclude-from='runtime_exclude.txt' --delete --delete-excluded ../runtime/ runtime

.PHONY: publish_pub
publish_pub:
	@echo "publishing.."
	@make clean
	@make update_cpp_runtime
	@echo "todo dowload all hash files, put in the correct directory"
	@echo "todo update hash checks to use package versions"
	@echo "todo actually run flutter pub publish"
	@echo "publish complete"

# Show help
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  clean         - Clean up generated files"
	@echo "  update_cpp_runtime - Update rive_native cpp runtime"
	@echo "  publish_pub   - Publish rive_native to Pub"
	@echo "  help          - Show this help message"
