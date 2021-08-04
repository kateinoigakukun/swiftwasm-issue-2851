set -x

while read file; do
    mkdir ./MinimumProject/$(basename $(dirname $file) /Users/kateinoigakukun/.ghq/github.com/kateinoigakukun/swiftwasm-issue-2851/.build/checkouts/Sources)
    cp $file ./MinimumProject/$(basename $(dirname $file))
done <filelist
