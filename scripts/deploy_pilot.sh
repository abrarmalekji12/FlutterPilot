oldVersion=$(<./scripts/version.txt);

newVersion=`expr $oldVersion + 1`

echo  "New Version : $newVersion";

echo "$newVersion" > ./scripts/version.txt;

value=$(<./web/index.html)
echo "$value" | sed "s/?version=$oldVersion/?version=$newVersion/g" > ./web/index.html

flutter clean && flutter pub get && flutter build web --release && firebase use flutterpilot && firebase deploy;