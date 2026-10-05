#!/bin/zsh
# Speiler Pakker/FargeKjerne til github.com/eivijoha/FargeKjerne og setter et versjonsmerke.
#
#     Pakker/publiser_fargekjerne.sh 0.2.0
#
# Kolorist-repoet er kilden (fase 1). Skriptet krever ren arbeidskopi for pakken, at testene går, og at CHANGELOG.md
# har en seksjon for versjonen. Merket settes bare i FargeKjerne-repoet, ikke i Kolorist.
set -euo pipefail

versjon=${1:?Bruk: publiser_fargekjerne.sh <versjon, f.eks. 0.2.0>}
[[ $versjon =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]] || { echo "Versjonen må være x.y.z"; exit 1; }
cd "$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
remote=git@github.com:eivijoha/FargeKjerne.git
prefix=Pakker/FargeKjerne

if [[ -n "$(git status --porcelain -- $prefix)" ]]; then
    echo "Pakken har ucommittede endringer – commit først."; exit 1
fi
grep -q "^## $versjon " $prefix/CHANGELOG.md || { echo "CHANGELOG.md mangler «## $versjon …»"; exit 1; }
if git ls-remote --tags $remote "refs/tags/$versjon" | grep -q .; then
    echo "Versjon $versjon finnes allerede i FargeKjerne-repoet."; exit 1
fi

echo "Tester pakken …"
(cd $prefix && swift test > /dev/null) || { echo "Testene feilet."; exit 1; }

echo "Speiler $prefix …"
commit=$(git subtree split --prefix=$prefix -q)
git push $remote "$commit:refs/heads/main"
git push $remote "$commit:refs/tags/$versjon"
echo "Publisert FargeKjerne $versjon ($commit)."
