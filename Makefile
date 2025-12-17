.PHONY: lint format test build

lint:
	swiftlint lint --strict
	swiftformat . --lint

format:
	swiftformat .

test:
	xcodebuild test \
		-project Ledger.xcodeproj \
		-scheme Ledger \
		-destination 'platform=macOS' \
		-skipMacroValidation \
		| xcpretty || true

build:
	xcodebuild build \
		-project Ledger.xcodeproj \
		-scheme Ledger \
		-destination 'generic/platform=iOS Simulator' \
		-skipMacroValidation \
		CODE_SIGNING_ALLOWED=NO \
		| xcpretty || true
