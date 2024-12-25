buf_generate:
	cd event_schema && buf generate --include-imports --include-wkt

buf_lint:
	cd event_schema && buf lint --error-format json

buf_format:
	cd event_schema && buf format -w

buf_lint_local:
	cd event_schema && buf lint