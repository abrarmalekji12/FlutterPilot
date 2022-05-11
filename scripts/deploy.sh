
# ./scripts/deploy.sh

#oldVersion=$(<./scripts/version.txt);
#
#newVersion=`expr $oldVersion + 1`
#
#echo  "\033[0;34mNew Version \033[0;32m $newVersion";
#
#echo "$newVersion" > ./scripts/version.txt;
#
#value=$(<./web/index.html)
#echo "$value" | sed "s/?version=$oldVersion/?version=$newVersion/g" > ./web/index.html

flutter clean && flutter pub get && flutter build web --release && firebase use flutter-visual-builder && firebase deploy;


flutter clean && flutter pub get && flutter build web --release && firebase use flutter-visual-builder-staging && firebase deploy;