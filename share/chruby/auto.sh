unset RUBY_AUTO_BUNDLE_BIN
unset RUBY_AUTO_VERSION

function chruby_auto_binstub_reset() {
	PATH=":$PATH:"
	PATH=${PATH//:$RUBY_AUTO_BUNDLE_BIN:/:}
	PATH="${PATH#:}"; PATH="${PATH%:}"
}

function chruby_auto() {
	local dir="$PWD" version auto_bundle_bin chruby_rc

	until [[ -z "$dir" ]]; do
		if { read -r version <"$dir/.ruby-version"; } 2>/dev/null || [[ -n "$version" ]]; then
			if [[ "$version" == "$RUBY_AUTO_VERSION" ]]; then
				chruby_rc=0
			else
				RUBY_AUTO_VERSION="$version"
				chruby "$version"
				chruby_rc=$?
			fi


			eval "$("$RUBY_ROOT/bin/ruby" - <<EOF
begin
	require 'rubygems'; require 'bundler'
	puts "export auto_bundle_bin=#{File.expand_path(Bundler.settings[:bin])}" unless Bundler.settings[:bin].nil?
rescue LoadError
end
EOF
)"

			if [[ -n "$RUBY_AUTO_BUNDLE_BIN" && "$RUBY_AUTO_BUNDLE_BIN" != "$auto_bundle_bin" ]]; then
				chruby_auto_binstub_reset
				unset RUBY_AUTO_BUNDLE_BIN
			fi

			if [[ -n "$auto_bundle_bin" ]]; then
				export RUBY_AUTO_BUNDLE_BIN="$auto_bundle_bin"
				export PATH=$RUBY_AUTO_BUNDLE_BIN:$PATH
			fi

			return $chruby_rc
		fi

		dir="${dir%/*}"
	done

	if [[ -n "$RUBY_AUTO_VERSION" ]]; then
		chruby_reset
		unset RUBY_AUTO_VERSION
	fi

	if [[ -n "$RUBY_AUTO_BUNDLE_BIN" ]]; then
		chruby_auto_binstub_reset
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
