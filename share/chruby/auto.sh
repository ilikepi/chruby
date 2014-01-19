unset RUBY_AUTO_VERSION

function chruby_auto() {
	local dir="$PWD" version chruby_rc

	until [[ -z "$dir" ]]; do
		if { read -r version <"$dir/.ruby-version"; } 2>/dev/null || [[ -n "$version" ]]; then
			if [[ "$version" == "$RUBY_AUTO_VERSION" && -n "$RUBY_ROOT" ]]; then return
			else
				RUBY_AUTO_VERSION="$version"
				chruby "$version"
				chruby_rc=$?
				[[ $chruby_rc == 0 ]] || chruby_reset
				return $chruby_rc
			fi
		fi

		dir="${dir%/*}"
	done

	if [[ -n "$RUBY_AUTO_VERSION" ]]; then
		chruby_reset
		unset RUBY_AUTO_VERSION
	fi
}

if [[ -n "$ZSH_VERSION" ]]; then
	if [[ ! "$preexec_functions" == *chruby_auto* ]]; then
		preexec_functions+=("chruby_auto")
	fi
elif [[ -n "$BASH_VERSION" ]]; then
	trap '[[ "$BASH_COMMAND" != "$PROMPT_COMMAND" ]] && chruby_auto' DEBUG
fi
