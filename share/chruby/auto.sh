unset RUBY_AUTO_BUNDLE_BIN
unset RUBY_AUTO_VERSION

function chruby_auto() {
	local dir="$PWD" version chruby_rc

	until [[ -z "$dir" ]]; do
		if { read -r version <"$dir/.ruby-version"; } 2>/dev/null || [[ -n "$version" ]]; then
			if [[ "$version" == "$RUBY_AUTO_VERSION" ]]; then return
			else
				RUBY_AUTO_VERSION="$version"
				chruby "$version"
				chruby_rc=$?

				eval "$("$RUBY_ROOT/bin/ruby" - <<EOF
begin
  require 'rubygems'; require 'bundler'
  puts "export RUBY_AUTO_BUNDLE_BIN=#{File.expand_path(Bundler.settings[:bin])}" unless Bundler.settings[:bin].nil?
rescue LoadError
end
EOF
)"

				if [[ -n "$RUBY_AUTO_BUNDLE_BIN" ]]; then
					export PATH=$RUBY_AUTO_BUNDLE_BIN:$PATH
				fi

				return $chruby_rc
			fi
		fi

		dir="${dir%/*}"
	done

	if [[ -n "$RUBY_AUTO_VERSION" ]]; then
		chruby_reset
		unset RUBY_AUTO_VERSION
	fi

	if [[ -n "$RUBY_AUTO_BUNDLE_BIN" ]]; then
		PATH=":$PATH:"
		PATH=${PATH//:$RUBY_AUTO_BUNDLE_BIN:/:}
		PATH="${PATH#:}"; PATH="${PATH%:}"
		unset RUBY_AUTO_BUNDLE_BIN
	fi
}

if [[ -n "$ZSH_VERSION" ]]; then
	if [[ ! "$preexec_functions" == *chruby_auto* ]]; then
		preexec_functions+=("chruby_auto")
	fi
elif [[ -n "$BASH_VERSION" ]]; then
	trap '[[ "$BASH_COMMAND" != "$PROMPT_COMMAND" ]] && chruby_auto' DEBUG
fi
