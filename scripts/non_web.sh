## IO lib
sed  -i  -e "s/ \/\*\/\/start_non_web/ \/\/start_non_web/" ./lib/common/web/io_lib.dart;
sed  -i  -e "s/ \*\/\/\/end_non_web/ \/\/end_non_web/" ./lib/common/web/io_lib.dart;
sed  -i  -e "s/ \/\/start_web/ \/\*\/\/start_web/" ./lib/common/web/io_lib.dart;
sed  -i  -e "s/ \/\/end_web/ \*\/\/\/end_web/" ./lib/common/web/io_lib.dart;

#JS lib
sed  -i  -e "s/ \/\*\/\/start_non_web/ \/\/start_non_web/" ./lib/common/web/js_lib.dart;
sed  -i  -e "s/ \*\/\/\/end_non_web/ \/\/end_non_web/" ./lib/common/web/js_lib.dart;
sed  -i  -e "s/ \/\/start_web/ \/\*\/\/start_web/" ./lib/common/web/js_lib.dart;
sed  -i  -e "s/ \/\/end_web/ \*\/\/\/end_web/" ./lib/common/web/js_lib.dart;

#HTML lib
sed  -i  -e "s/ \/\*\/\/start_non_web/ \/\/start_non_web/" ./lib/common/web/html_lib.dart;
sed  -i  -e "s/ \*\/\/\/end_non_web/ \/\/end_non_web/" ./lib/common/web/html_lib.dart;
sed  -i  -e "s/ \/\/start_web/ \/\*\/\/start_web/" ./lib/common/web/html_lib.dart;
sed  -i  -e "s/ \/\/end_web/ \*\/\/\/end_web/" ./lib/common/web/html_lib.dart;

#Firestore
sed  -i  -e "s/ \/\*\/\/start_non_win/ \/\/start_non_win/" ./lib/data/remote/firestore/firebase_lib.dart;
sed  -i  -e "s/ \*\/\/\/end_non_win/ \/\/end_non_win/" ./lib/data/remote/firestore/firebase_lib.dart;
sed  -i  -e "s/ \/\/start_win/ \/\*\/\/start_win/" ./lib/data/remote/firestore/firebase_lib.dart;
sed  -i  -e "s/ \/\/end_win/ \*\/\/\/end_win/" ./lib/data/remote/firestore/firebase_lib.dart;
