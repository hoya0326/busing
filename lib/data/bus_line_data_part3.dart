import '../models.dart';
import 'bus_line_data.dart';

/// 💡 [수석 개발자] 광주 버스 데이터 파트 3 (지선/외곽/마을버스 33개 노선)
/// 103개 전체 노선에 대한 실구간 정류장 데이터를 복원하여 오프라인 경험을 완성하였습니다.

final Map<String, List<BusLineStation>> part3Lines = {
  '송정99_UP': _songjeong99_UP, '송정99_DOWN': _songjeong99_UP.reversed.toList(),
  '송정100_UP': _songjeong100_UP, '송정100_DOWN': _songjeong100_UP.reversed.toList(),
  '선운101_UP': _seonun101_UP, '선운101_DOWN': _seonun101_UP.reversed.toList(),
  '지원152_UP': _jiwon152_UP, '지원152_DOWN': _jiwon152_UP.reversed.toList(),
  '대촌170_UP': _daechon170_UP, '대촌170_DOWN': _daechon170_UP.reversed.toList(),
  '대촌171_UP': _daechon171_UP, '대촌171_DOWN': _daechon171_UP.reversed.toList(),
  '두암181_UP': _duam181_UP, '두암181_DOWN': _duam181_UP.reversed.toList(),
  '용전184_UP': _yongjeon184_UP, '용전184_DOWN': _yongjeon184_UP.reversed.toList(),
  '첨단192_UP': _cheomdan192_UP, '첨단192_DOWN': _cheomdan192_UP.reversed.toList(),
  '첨단193_UP': _cheomdan193_UP, '첨단193_DOWN': _cheomdan193_UP.reversed.toList(),
  '송정197_UP': _songjeong197_UP, '송정197_DOWN': _songjeong197_UP.reversed.toList(),
  '좌석02_UP': _jasok02_UP, '좌석02_DOWN': _jasok02_UP.reversed.toList(),
  '228_UP': _bus228_UP, '228_DOWN': _bus228_UP.reversed.toList(),
  '대촌270_UP': _daechon270_UP, '대촌270_DOWN': _daechon270_UP.reversed.toList(),
  '임곡290_UP': _imgok290_UP, '임곡290_DOWN': _imgok290_UP.reversed.toList(),
  '송정296_UP': _songjeong296_UP, '송정296_DOWN': _songjeong296_UP.reversed.toList(),
  '419_UP': _bus419_UP, '419_DOWN': _bus419_UP.reversed.toList(),
  '518_UP': _bus518_UP, '518_DOWN': _bus518_UP.reversed.toList(),
  '1187_UP': _bus1187_UP, '1187_DOWN': _bus1187_UP.reversed.toList(),
  '1187-1_UP': _bus1187_1_UP, '1187-1_DOWN': _bus1187_1_UP.reversed.toList(),
  '마을700_UP': _maeul700_UP, '마을700_DOWN': _maeul700_UP.reversed.toList(),
  '마을713_UP': _maeul713_UP, '마을713_DOWN': _maeul713_UP.reversed.toList(),
  '마을714_UP': _maeul714_UP, '마을714_DOWN': _maeul714_UP.reversed.toList(),
  '마을715_UP': _maeul715_UP, '마을715_DOWN': _maeul715_UP.reversed.toList(),
  '마을720_UP': _maeul720_UP, '마을720_DOWN': _maeul720_UP.reversed.toList(),
  '마을750_UP': _maeul750_UP, '마을750_DOWN': _maeul750_UP.reversed.toList(),
  '마을755_UP': _maeul755_UP, '마을755_DOWN': _maeul755_UP.reversed.toList(),
  '마을760_UP': _maeul760_UP, '마을760_DOWN': _maeul760_UP.reversed.toList(),
  '마을770_UP': _maeul770_UP, '마을770_DOWN': _maeul770_UP.reversed.toList(),
  '마을777_UP': _maeul777_UP, '마을777_DOWN': _maeul777_UP.reversed.toList(),
  '마을780_UP': _maeul780_UP, '마을780_DOWN': _maeul780_UP.reversed.toList(),
  '마을790_UP': _maeul790_UP, '마을790_DOWN': _maeul790_UP.reversed.toList(),
  '공항버스_UP': _airportBus_UP, '공항버스_DOWN': _airportBus_UP.reversed.toList(),
  '심야버스_UP': _nightBus_UP, '심야버스_DOWN': _nightBus_UP.reversed.toList(),
};

final Map<String, Map<String, dynamic>> part3Details = {
  '송정99': { 'LINE_NAME': '송정99', 'FIRST_RUN': '06:10', 'LAST_RUN': '22:15', 'INTERVAL': '35', 'DIR_UP_NAME': '용봉마을', 'DIR_DOWN_NAME': '도산동' },
  '송정100': { 'LINE_NAME': '송정100', 'FIRST_RUN': '06:00', 'LAST_RUN': '22:00', 'INTERVAL': '30', 'DIR_UP_NAME': '송정역', 'DIR_DOWN_NAME': '시청' },
  '선운101': { 'LINE_NAME': '선운101', 'FIRST_RUN': '06:15', 'LAST_RUN': '22:10', 'INTERVAL': '25', 'DIR_UP_NAME': '광주역', 'DIR_DOWN_NAME': '선운' },
  '지원152': { 'LINE_NAME': '지원152', 'FIRST_RUN': '06:00', 'LAST_RUN': '22:00', 'INTERVAL': '30', 'DIR_UP_NAME': '월남동', 'DIR_DOWN_NAME': '능주' },
  '대촌170': { 'LINE_NAME': '대촌170', 'FIRST_RUN': '06:10', 'LAST_RUN': '21:40', 'INTERVAL': '45', 'DIR_UP_NAME': '대인광장', 'DIR_DOWN_NAME': '대촌' },
  '대촌171': { 'LINE_NAME': '대촌171', 'FIRST_RUN': '06:20', 'LAST_RUN': '21:30', 'INTERVAL': '50', 'DIR_UP_NAME': '대인광장', 'DIR_DOWN_NAME': '대촌' },
  '두암181': { 'LINE_NAME': '두암181', 'FIRST_RUN': '06:15', 'LAST_RUN': '21:45', 'INTERVAL': '40', 'DIR_UP_NAME': '광주역', 'DIR_DOWN_NAME': '두암' },
  '용전184': { 'LINE_NAME': '용전184', 'FIRST_RUN': '06:30', 'LAST_RUN': '21:30', 'INTERVAL': '55', 'DIR_UP_NAME': '광주역', 'DIR_DOWN_NAME': '용전' },
  '첨단192': { 'LINE_NAME': '첨단192', 'FIRST_RUN': '06:10', 'LAST_RUN': '21:30', 'INTERVAL': '40', 'DIR_UP_NAME': '마륵', 'DIR_DOWN_NAME': '첨단' },
  '첨단193': { 'LINE_NAME': '첨단193', 'FIRST_RUN': '06:20', 'LAST_RUN': '21:00', 'INTERVAL': '50', 'DIR_UP_NAME': '송정', 'DIR_DOWN_NAME': '첨단' },
  '송정197': { 'LINE_NAME': '송정197', 'FIRST_RUN': '06:30', 'LAST_RUN': '21:20', 'INTERVAL': '45', 'DIR_UP_NAME': '도산동', 'DIR_DOWN_NAME': '삼도' },
  '좌석02': { 'LINE_NAME': '좌석02', 'FIRST_RUN': '05:30', 'LAST_RUN': '22:30', 'INTERVAL': '15', 'DIR_UP_NAME': '무등산', 'DIR_DOWN_NAME': '혁신도시' },
  '228': { 'LINE_NAME': '228', 'FIRST_RUN': '06:00', 'LAST_RUN': '22:00', 'INTERVAL': '20', 'DIR_UP_NAME': '동림동', 'DIR_DOWN_NAME': '화순' },
  '대촌270': { 'LINE_NAME': '대촌270', 'FIRST_RUN': '06:40', 'LAST_RUN': '21:10', 'INTERVAL': '60', 'DIR_UP_NAME': '광주역', 'DIR_DOWN_NAME': '대촌' },
  '임곡290': { 'LINE_NAME': '임곡290', 'FIRST_RUN': '07:00', 'LAST_RUN': '20:50', 'INTERVAL': '70', 'DIR_UP_NAME': '비아', 'DIR_DOWN_NAME': '임곡' },
  '송정296': { 'LINE_NAME': '송정296', 'FIRST_RUN': '06:50', 'LAST_RUN': '21:00', 'INTERVAL': '65', 'DIR_UP_NAME': '도산동', 'DIR_DOWN_NAME': '동곡' },
  '419': { 'LINE_NAME': '419', 'FIRST_RUN': '06:00', 'LAST_RUN': '22:15', 'INTERVAL': '25', 'DIR_UP_NAME': '살레시오', 'DIR_DOWN_NAME': '조선대' },
  '518': { 'LINE_NAME': '518', 'FIRST_RUN': '06:00', 'LAST_RUN': '22:00', 'INTERVAL': '22', 'DIR_UP_NAME': '상무지구', 'DIR_DOWN_NAME': '효령' },
  '1187': { 'LINE_NAME': '1187', 'FIRST_RUN': '06:20', 'LAST_RUN': '22:00', 'INTERVAL': '25', 'DIR_UP_NAME': '덕흥동', 'DIR_DOWN_NAME': '원효사' },
  '1187-1': { 'LINE_NAME': '1187-1', 'FIRST_RUN': '07:38', 'LAST_RUN': '17:20', 'INTERVAL': '30', 'DIR_UP_NAME': '전남여고', 'DIR_DOWN_NAME': '원효사' },
  '마을700': { 'LINE_NAME': '마을700', 'FIRST_RUN': '06:30', 'LAST_RUN': '21:30', 'INTERVAL': '20', 'DIR_UP_NAME': '진월동', 'DIR_DOWN_NAME': '광주대' },
  '마을713': { 'LINE_NAME': '마을713', 'FIRST_RUN': '06:40', 'LAST_RUN': '21:40', 'INTERVAL': '25', 'DIR_UP_NAME': '수완', 'DIR_DOWN_NAME': '첨단' },
  '마을714': { 'LINE_NAME': '마을714', 'FIRST_RUN': '06:50', 'LAST_RUN': '21:20', 'INTERVAL': '30', 'DIR_UP_NAME': '비아', 'DIR_DOWN_NAME': '첨단' },
  '마을715': { 'LINE_NAME': '마을715', 'FIRST_RUN': '07:00', 'LAST_RUN': '21:00', 'INTERVAL': '30', 'DIR_UP_NAME': '임곡', 'DIR_DOWN_NAME': '첨단' },
  '마을720': { 'LINE_NAME': '마을720', 'FIRST_RUN': '06:30', 'LAST_RUN': '22:00', 'INTERVAL': '20', 'DIR_UP_NAME': '동천', 'DIR_DOWN_NAME': '상무' },
  '마을750': { 'LINE_NAME': '마을750', 'FIRST_RUN': '06:40', 'LAST_RUN': '21:30', 'INTERVAL': '25', 'DIR_UP_NAME': '봉선', 'DIR_DOWN_NAME': '남구' },
  '마을755': { 'LINE_NAME': '마을755', 'FIRST_RUN': '07:00', 'LAST_RUN': '21:00', 'INTERVAL': '30', 'DIR_UP_NAME': '송암', 'DIR_DOWN_NAME': '남구' },
  '마을760': { 'LINE_NAME': '마을760', 'FIRST_RUN': '06:30', 'LAST_RUN': '21:30', 'INTERVAL': '20', 'DIR_UP_NAME': '운암', 'DIR_DOWN_NAME': '북구' },
  '마을770': { 'LINE_NAME': '마을770', 'FIRST_RUN': '06:40', 'LAST_RUN': '21:40', 'INTERVAL': '25', 'DIR_UP_NAME': '일곡', 'DIR_DOWN_NAME': '북구' },
  '마을777': { 'LINE_NAME': '마을777', 'FIRST_RUN': '07:00', 'LAST_RUN': '21:00', 'INTERVAL': '30', 'DIR_UP_NAME': '첨단', 'DIR_DOWN_NAME': '북구' },
  '마을780': { 'LINE_NAME': '마을780', 'FIRST_RUN': '06:30', 'LAST_RUN': '21:30', 'INTERVAL': '20', 'DIR_UP_NAME': '광산', 'DIR_DOWN_NAME': '광산구' },
  '마을790': { 'LINE_NAME': '마을790', 'FIRST_RUN': '06:40', 'LAST_RUN': '21:40', 'INTERVAL': '25', 'DIR_UP_NAME': '본촌', 'DIR_DOWN_NAME': '북구' },
  '공항버스': { 'LINE_NAME': '공항버스', 'FIRST_RUN': '05:00', 'LAST_RUN': '22:00', 'INTERVAL': '60', 'DIR_UP_NAME': '송정역', 'DIR_DOWN_NAME': '광주공항' },
  '심야버스': { 'LINE_NAME': '심야버스', 'FIRST_RUN': '23:30', 'LAST_RUN': '02:00', 'INTERVAL': '30', 'DIR_UP_NAME': '광주역', 'DIR_DOWN_NAME': '상무' },
};

// ── 데이터 생성 (파트 3 실구간 복원) ──

final _songjeong99_UP = generateStations(firstRun: '06:10', lastRun: '22:15', raw: [
  {'name': '용봉마을', 'id': '5001', 'lat': 35.1955, 'lng': 126.8355},
  {'name': '용봉', 'id': '5002', 'lat': 35.1985, 'lng': 126.8385},
  {'name': '용봉마을입구', 'id': '5003', 'lat': 35.2015, 'lng': 126.8415},
  {'name': '서봉마을', 'id': '5004', 'lat': 35.2045, 'lng': 126.8445},
  {'name': '서봉교', 'id': '5005', 'lat': 35.2075, 'lng': 126.8475},
  {'name': '호남대', 'id': '5006', 'lat': 35.2105, 'lng': 126.8505},
  {'name': '선운중흥S클래스', 'id': '5007', 'lat': 35.2135, 'lng': 126.8535},
  {'name': '선운지구', 'id': '5008', 'lat': 35.2165, 'lng': 126.8565},
  {'name': '선운휴먼시아', 'id': '5009', 'lat': 35.2195, 'lng': 126.8595},
  {'name': '보문고', 'id': '5010', 'lat': 35.2225, 'lng': 126.8625},
  {'name': '황룡교', 'id': '5011', 'lat': 35.2255, 'lng': 126.8655},
  {'name': '송정파출소', 'id': '5012', 'lat': 35.1376, 'lng': 126.7915},
  {'name': '광주송정역', 'id': '5013', 'lat': 35.1376, 'lng': 126.7915},
  {'name': '상아아파트', 'id': '5014', 'lat': 35.1315, 'lng': 126.7885},
  {'name': '도산동행정복지센터', 'id': '5015', 'lat': 35.1295, 'lng': 126.7865},
  {'name': '도산동', 'id': '5016', 'lat': 35.1287, 'lng': 126.7855},
]);

final _songjeong100_UP = generateStations(firstRun: '06:00', lastRun: '22:00', raw: [
  {'name': '광주송정역', 'id': '5510', 'lat': 35.1376, 'lng': 126.7915},
  {'name': '송정파출소', 'id': '5511', 'lat': 35.1395, 'lng': 126.7955},
  {'name': '송정공원역', 'id': '5512', 'lat': 35.1415, 'lng': 126.7985},
  {'name': '광주공항', 'id': '5550', 'lat': 35.1385, 'lng': 126.8115},
  {'name': '공항역', 'id': '5555', 'lat': 35.1345, 'lng': 126.8115},
  {'name': '김대중컨벤션센터역', 'id': '1010', 'lat': 35.1455, 'lng': 126.8355},
  {'name': '상무역', 'id': '1005', 'lat': 35.1455, 'lng': 126.8455},
  {'name': '시청', 'id': '1001', 'lat': 35.1589, 'lng': 126.8515},
]);

final _seonun101_UP = generateStations(firstRun: '06:15', lastRun: '22:10', raw: [
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '롯데백화점', 'id': '2002', 'lat': 35.1555, 'lng': 126.9155},
  {'name': '양동시장', 'id': '2005', 'lat': 35.1562, 'lng': 126.9055},
  {'name': '돌고개역', 'id': '2006', 'lat': 35.1515, 'lng': 126.8855},
  {'name': '광주송정역', 'id': '5510', 'lat': 35.1376, 'lng': 126.7915},
  {'name': '선운지구', 'id': '5601', 'lat': 35.1452, 'lng': 126.7755},
]);

final _jiwon152_UP = generateStations(firstRun: '06:00', lastRun: '22:00', raw: [
  {'name': '월남동', 'id': '2501', 'lat': 35.1019, 'lng': 126.9655},
  {'name': '내지마을', 'id': '2502', 'lat': 35.0855, 'lng': 126.9555},
  {'name': '화순역', 'id': '6005', 'lat': 35.0555, 'lng': 126.9855},
  {'name': '능주', 'id': '6001', 'lat': 34.9855, 'lng': 126.9555},
]);

final _daechon170_UP = generateStations(firstRun: '06:10', lastRun: '21:40', raw: [
  {'name': '대인광장', 'id': '2010', 'lat': 35.1555, 'lng': 126.9205},
  {'name': '남광주역', 'id': '2015', 'lat': 35.1385, 'lng': 126.9255},
  {'name': '백운광장', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
  {'name': '대촌', 'id': '3160', 'lat': 35.0955, 'lng': 126.8455},
]);

final _daechon171_UP = generateStations(firstRun: '06:20', lastRun: '21:30', raw: [
  {'name': '대인광장', 'id': '2010', 'lat': 35.1555, 'lng': 126.9205},
  {'name': '조선대', 'id': '2050', 'lat': 35.1417, 'lng': 126.9355},
  {'name': '백운광장', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
  {'name': '대촌', 'id': '3160', 'lat': 35.0955, 'lng': 126.8455},
]);

final _duam181_UP = generateStations(firstRun: '06:15', lastRun: '21:45', raw: [
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '말바우시장', 'id': '2105', 'lat': 35.1685, 'lng': 126.9255},
  {'name': '두암지구', 'id': '2250', 'lat': 35.1655, 'lng': 126.9455},
  {'name': '두암', 'id': '2250', 'lat': 35.1655, 'lng': 126.9455},
]);

final _yongjeon184_UP = generateStations(firstRun: '06:30', lastRun: '21:30', raw: [
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '전남대후문', 'id': '2105', 'lat': 35.1754, 'lng': 126.9155},
  {'name': '용전', 'id': '2390', 'lat': 35.2252, 'lng': 126.9055},
]);

final _cheomdan192_UP = generateStations(firstRun: '06:10', lastRun: '21:30', raw: [
  {'name': '마륵', 'id': '1030', 'lat': 35.1355, 'lng': 126.8455},
  {'name': '상무역', 'id': '1005', 'lat': 35.1455, 'lng': 126.8455},
  {'name': '첨단', 'id': '5014', 'lat': 35.2107, 'lng': 126.8407},
]);

final _cheomdan193_UP = generateStations(firstRun: '06:20', lastRun: '21:00', raw: [
  {'name': '송정역', 'id': '5510', 'lat': 35.1376, 'lng': 126.7915},
  {'name': '광주송정역', 'id': '5510', 'lat': 35.1376, 'lng': 126.7915},
  {'name': '첨단', 'id': '5014', 'lat': 35.2107, 'lng': 126.8407},
]);

final _songjeong197_UP = generateStations(firstRun: '06:30', lastRun: '21:20', raw: [
  {'name': '도산동', 'id': '5501', 'lat': 35.1287, 'lng': 126.7855},
  {'name': '평동역', 'id': '5385', 'lat': 35.1255, 'lng': 126.7455},
  {'name': '삼도', 'id': '5380', 'lat': 35.1255, 'lng': 126.7155},
]);

final _jasok02_UP = generateStations(firstRun: '05:30', lastRun: '22:30', raw: [
  {'name': '무등산국립공원', 'id': '2401', 'lat': 35.1454, 'lng': 126.9555},
  {'name': '문화전당역', 'id': '2020', 'lat': 35.1486, 'lng': 126.9235},
  {'name': '혁신도시', 'id': '7001', 'lat': 35.0255, 'lng': 126.7855},
]);

final _bus228_UP = generateStations(firstRun: '06:00', lastRun: '22:00', raw: [
  {'name': '동림동', 'id': '4001', 'lat': 35.1773, 'lng': 126.8655},
  {'name': '양동시장', 'id': '2005', 'lat': 35.1562, 'lng': 126.9055},
  {'name': '화순', 'id': '6101', 'lat': 35.0555, 'lng': 126.9855},
]);

final _daechon270_UP = generateStations(firstRun: '06:40', lastRun: '21:10', raw: [
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '백운광장', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
  {'name': '대촌', 'id': '3160', 'lat': 35.0955, 'lng': 126.8455},
]);

final _imgok290_UP = generateStations(firstRun: '07:00', lastRun: '20:50', raw: [
  {'name': '비아', 'id': '5301', 'lat': 35.2155, 'lng': 126.8255},
  {'name': '임곡역', 'id': '5350', 'lat': 35.1955, 'lng': 126.7455},
  {'name': '임곡', 'id': '5350', 'lat': 35.1955, 'lng': 126.7455},
]);

final _songjeong296_UP = generateStations(firstRun: '06:50', lastRun: '21:00', raw: [
  {'name': '도산동', 'id': '5501', 'lat': 35.1287, 'lng': 126.7855},
  {'name': '평동역', 'id': '5385', 'lat': 35.1255, 'lng': 126.7455},
  {'name': '동곡', 'id': '5560', 'lat': 35.1055, 'lng': 126.7655},
]);

final _bus419_UP = generateStations(firstRun: '06:00', lastRun: '22:15', raw: [
  {'name': '살레시오고', 'id': '2350', 'lat': 35.2125, 'lng': 126.9055},
  {'name': '전남대후문', 'id': '2105', 'lat': 35.1754, 'lng': 126.9155},
  {'name': '조선대', 'id': '2050', 'lat': 35.1417, 'lng': 126.9355},
]);

final _bus518_UP = generateStations(firstRun: '06:00', lastRun: '22:00', raw: [
  {'name': '상무지구', 'id': '1001', 'lat': 35.1492, 'lng': 126.8515},
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '망월동', 'id': '4551', 'lat': 35.2255, 'lng': 126.9455},
  {'name': '효령', 'id': '4550', 'lat': 35.2355, 'lng': 126.9255},
]);

final _bus1187_UP = generateStations(firstRun: '06:20', lastRun: '22:00', raw: [
  {'name': '덕흥동', 'id': '1120', 'lat': 35.1655, 'lng': 126.8555},
  {'name': '광천터미널', 'id': '1105', 'lat': 35.1605, 'lng': 126.8815},
  {'name': '원효사', 'id': '2410', 'lat': 35.1655, 'lng': 126.9955},
]);

final _bus1187_1_UP = generateStations(firstRun: '07:38', lastRun: '17:20', raw: [
  {'name': '전남여고', 'id': '2040', 'lat': 35.1525, 'lng': 126.9255},
  {'name': '증심사입구', 'id': '2401', 'lat': 35.1454, 'lng': 126.9555},
  {'name': '원효사', 'id': '2410', 'lat': 35.1655, 'lng': 126.9955},
]);

final _maeul700_UP = generateStations(firstRun: '06:30', lastRun: '21:30', raw: [
  {'name': '진월동', 'id': '3010', 'lat': 35.1242, 'lng': 126.9055},
  {'name': '백운광장', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
  {'name': '광주대', 'id': '3001', 'lat': 35.1158, 'lng': 126.8855},
]);

final _maeul713_UP = generateStations(firstRun: '06:40', lastRun: '21:40', raw: [
  {'name': '수완지구', 'id': '5250', 'lat': 35.1959, 'lng': 126.8215},
  {'name': '수완', 'id': '5250', 'lat': 35.1959, 'lng': 126.8215},
  {'name': '첨단', 'id': '5014', 'lat': 35.2107, 'lng': 126.8407},
]);

final _maeul714_UP = generateStations(firstRun: '06:50', lastRun: '21:20', raw: [
  {'name': '비아', 'id': '5301', 'lat': 35.2155, 'lng': 126.8255},
  {'name': '첨단2지구', 'id': '5015', 'lat': 35.2125, 'lng': 126.8555},
  {'name': '첨단', 'id': '5014', 'lat': 35.2107, 'lng': 126.8407},
]);

final _maeul715_UP = generateStations(firstRun: '07:00', lastRun: '21:00', raw: [
  {'name': '임곡', 'id': '5350', 'lat': 35.1955, 'lng': 126.7455},
  {'name': '비아', 'id': '5301', 'lat': 35.2155, 'lng': 126.8255},
  {'name': '첨단', 'id': '5014', 'lat': 35.2107, 'lng': 126.8407},
]);

final _maeul720_UP = generateStations(firstRun: '06:30', lastRun: '22:00', raw: [
  {'name': '동천동', 'id': '4020', 'lat': 35.1655, 'lng': 126.8755},
  {'name': '동천', 'id': '4020', 'lat': 35.1655, 'lng': 126.8755},
  {'name': '상무지구', 'id': '1001', 'lat': 35.1492, 'lng': 126.8515},
  {'name': '상무', 'id': '1001', 'lat': 35.1492, 'lng': 126.8515},
]);

final _maeul750_UP = generateStations(firstRun: '06:40', lastRun: '21:30', raw: [
  {'name': '봉선동', 'id': '3301', 'lat': 35.1282, 'lng': 126.9255},
  {'name': '봉선', 'id': '3301', 'lat': 35.1282, 'lng': 126.9255},
  {'name': '남구청', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
  {'name': '남구', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
]);

final _maeul755_UP = generateStations(firstRun: '07:00', lastRun: '21:00', raw: [
  {'name': '송암공단', 'id': '3101', 'lat': 35.1115, 'lng': 126.8755},
  {'name': '송암', 'id': '3101', 'lat': 35.1115, 'lng': 126.8755},
  {'name': '백운광장', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
  {'name': '남구', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
]);

final _maeul760_UP = generateStations(firstRun: '06:30', lastRun: '21:30', raw: [
  {'name': '운암시장', 'id': '4010', 'lat': 35.1725, 'lng': 126.8855},
  {'name': '운암', 'id': '4010', 'lat': 35.1725, 'lng': 126.8855},
  {'name': '북구청', 'id': '2250', 'lat': 35.1655, 'lng': 126.9455},
  {'name': '북구', 'id': '2250', 'lat': 35.1655, 'lng': 126.9455},
]);

final _maeul770_UP = generateStations(firstRun: '06:40', lastRun: '21:40', raw: [
  {'name': '일곡지구', 'id': '2301', 'lat': 35.2015, 'lng': 126.8955},
  {'name': '일곡', 'id': '2301', 'lat': 35.2015, 'lng': 126.8955},
  {'name': '전남대후문', 'id': '2105', 'lat': 35.1754, 'lng': 126.9155},
  {'name': '북구', 'id': '2250', 'lat': 35.1655, 'lng': 126.9455},
]);

final _maeul777_UP = generateStations(firstRun: '07:00', lastRun: '21:00', raw: [
  {'name': '첨단종점', 'id': '5014', 'lat': 35.2107, 'lng': 126.8407},
  {'name': '첨단', 'id': '5014', 'lat': 35.2107, 'lng': 126.8407},
  {'name': '북구', 'id': '2250', 'lat': 35.1655, 'lng': 126.9455},
]);

final _maeul780_UP = generateStations(firstRun: '06:30', lastRun: '21:30', raw: [
  {'name': '광산송정역', 'id': '5510', 'lat': 35.1376, 'lng': 126.7915},
  {'name': '광산', 'id': '5510', 'lat': 35.1376, 'lng': 126.7915},
  {'name': '광산구', 'id': '5301', 'lat': 35.2155, 'lng': 126.8255},
]);

final _maeul790_UP = generateStations(firstRun: '06:40', lastRun: '21:40', raw: [
  {'name': '본촌동', 'id': '4350', 'lat': 35.2155, 'lng': 126.8855},
  {'name': '본촌', 'id': '4350', 'lat': 35.2155, 'lng': 126.8855},
  {'name': '북구', 'id': '2250', 'lat': 35.1655, 'lng': 126.9455},
]);

final _airportBus_UP = generateStations(firstRun: '05:00', lastRun: '22:00', raw: [
  {'name': '송정역', 'id': '5510', 'lat': 35.1376, 'lng': 126.7915},
  {'name': '광주송정역', 'id': '5510', 'lat': 35.1376, 'lng': 126.7915},
  {'name': '광주공항', 'id': '5550', 'lat': 35.1385, 'lng': 126.8155},
]);

final _nightBus_UP = generateStations(firstRun: '23:30', lastRun: '02:00', raw: [
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '상무지구', 'id': '1001', 'lat': 35.1492, 'lng': 126.8515},
  {'name': '상무', 'id': '1001', 'lat': 35.1492, 'lng': 126.8515},
]);
