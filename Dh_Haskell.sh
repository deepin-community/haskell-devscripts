# Copyright © 2022 Felix Lechner <felix.lechner@lease-up.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

recipe(){
    local -x RECIPE="$1"
    shift
    perl -d:Confess \
         -MDebian::Debhelper::Buildsystem::Haskell::Recipes=/.*/ \
         -MUnicode::UTF8=decode_utf8,encode_utf8 \
         -E 'my @decoded = map { decode_utf8($_) } @ARGV; my @results = $ENV{RECIPE}->(@decoded); my $output = join(q{ }, @results); say encode_utf8($output) if length $output;' "$@" \
        || exit
}

# sole use in
# https://git.spwhitton.name/pandoc-citeproc-preamble/tree/debian/rules#n18
hashed_dependency(){
    recipe "${FUNCNAME[0]}" "$@"
}
