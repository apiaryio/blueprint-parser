# ===== Directories =====

SRC_DIR              = src
LIB_DIR              = lib
DIST_DIR             = dist
NODE_MODULES_DIR     = node_modules
NODE_MODULES_BIN_DIR = $(NODE_MODULES_DIR)/.bin

# ===== Files =====

PARSER_SRC_FILE = $(SRC_DIR)/apiary-blueprint-parser.pegjs
PARSER_OUT_FILE = $(LIB_DIR)/apiary-blueprint-parser.js

AST_SRC_FILE = $(SRC_DIR)/ast.coffee
AST_OUT_FILE = $(LIB_DIR)/ast.js

BROWSER_FILE = $(DIST_DIR)/apiary-blueprint-parser.js

VERSION_FILE = VERSION

# ===== Executables =====

COFFEE = $(NODE_MODULES_BIN_DIR)/coffee
PEGJS  = $(NODE_MODULES_BIN_DIR)/pegjs
MOCHA  = $(NODE_MODULES_BIN_DIR)/mocha

# ===== Targets =====

all: build browser

$(LIB_DIR):
	mkdir -p $(LIB_DIR)

$(DIST_DIR):
	mkdir -p $(DIST_DIR)

$(AST_OUT_FILE): $(LIB_DIR) $(AST_SRC_FILE)
	$(COFFEE) --compile --bare --output $(LIB_DIR) $(AST_SRC_FILE)

$(PARSER_OUT_FILE): $(LIB_DIR) $(PARSER_SRC_FILE) $(AST_OUT_FILE)
	$(PEGJS) $(PARSER_SRC_FILE) $(PARSER_OUT_FILE)
	echo "" >> $(PARSER_OUT_FILE)
	echo "module.exports.ast = require(\"./ast\");" >> $(PARSER_OUT_FILE)

$(BROWSER_FILE): $(DIST_DIR) $(PARSER_OUT_FILE) $(AST_OUT_FILE)
	rm -f $(BROWSER_FILE)

	# The following code is inspired by CoffeeScript's Cakefile.

	echo "/*"                                               >> $(BROWSER_FILE)
	echo " * Apiary Blueprint Parser `cat $(VERSION_FILE)`" >> $(BROWSER_FILE)
	echo " *"                                               >> $(BROWSER_FILE)
	echo " * https://github.com/apiaryio/blueprint-parser"  >> $(BROWSER_FILE)
	echo " *"                                               >> $(BROWSER_FILE)
	echo " * Copyright (c) 2012-2013 Apiary Ltd."           >> $(BROWSER_FILE)
	echo " * Licensed under the MIT license"                >> $(BROWSER_FILE)
	echo " */"                                              >> $(BROWSER_FILE)
	echo "var ApiaryBlueprintParser = (function() {"        >> $(BROWSER_FILE)
	echo ""                                                 >> $(BROWSER_FILE)
	echo "function require(path) {"                         >> $(BROWSER_FILE)
	echo "  return require[path];"                          >> $(BROWSER_FILE)
	echo "}"                                                >> $(BROWSER_FILE)
	echo ""                                                 >> $(BROWSER_FILE)

	for module in ast apiary-blueprint-parser; do                        \
	  echo "require[\"./$$module\"] = (function() {" >> $(BROWSER_FILE); \
	  echo "var module = { exports: {} };"           >> $(BROWSER_FILE); \
	  echo ""                                        >> $(BROWSER_FILE); \
	  cat  "lib/$$module.js"                         >> $(BROWSER_FILE); \
	  echo ""                                        >> $(BROWSER_FILE); \
	  echo "return module.exports;"                  >> $(BROWSER_FILE); \
	  echo "})();"                                   >> $(BROWSER_FILE); \
	  echo ""                                        >> $(BROWSER_FILE); \
	done

	echo "return require[\"./apiary-blueprint-parser\"]" >> $(BROWSER_FILE)
	echo "})();"                                         >> $(BROWSER_FILE)

# Build the library
build: $(PARSER_OUT_FILE)

# Build the browser version of the library
browser: $(BROWSER_FILE)

# Run the test suite
test: build
	$(MOCHA) --compilers coffee:coffee-script

.PHONY: build browser test
.SILENT: build browser test $(LIB_DIR) $(DIST_DIR) $(AST_OUT_FILE) $(PARSER_OUT_FILE) $(BROWSER_FILE)
