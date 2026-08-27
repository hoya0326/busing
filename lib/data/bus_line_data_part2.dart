import '../models.dart';
import 'bus_line_data.dart';

/// 💡 [수석 개발자] 광주 버스 데이터 파트 2 (간선 및 지선 36개 노선)
/// XLS 데이터의 노선별 정류장 정보를 sequential하게 복원하였습니다.

final Map<String, List<BusLineStation>> part2Lines = {
  '운림54_UP': _unlim54_UP, '운림54_DOWN': _unlim54_UP.reversed.toList(),
  '금남55_UP': _geumnam55_UP, '금남55_DOWN': _geumnam55_UP.reversed.toList(),
  '금남57_UP': _geumnam57_UP, '금남57_DOWN': _geumnam57_UP.reversed.toList(),
  '금남58_UP': _geumnam58_UP, '금남58_DOWN': _geumnam58_UP.reversed.toList(),
  '금남59_UP': _geumnam59_UP, '금남59_DOWN': _geumnam59_UP.reversed.toList(),
  '양산60_UP': _yangsan60_UP, '양산60_DOWN': _yangsan60_UP.reversed.toList(),
  '매월61_UP': _maewol61_UP, '매월61_DOWN': _maewol61_UP.reversed.toList(),
  '상무62_UP': _sangmu62_UP, '상무62_DOWN': _sangmu62_UP.reversed.toList(),
  '상무63_UP': _sangmu63_UP, '상무63_DOWN': _sangmu63_UP.reversed.toList(),
  '상무64_UP': _sangmu64_UP, '상무64_DOWN': _sangmu64_UP.reversed.toList(),
  '유덕65_UP': _yudeok65_UP, '유덕65_DOWN': _yudeok65_UP.reversed.toList(),
  '송암68_UP': _songam68_UP, '송암68_DOWN': _songam68_UP.reversed.toList(),
  '대촌69_UP': _daechon69_UP, '대촌69_DOWN': _daechon69_UP.reversed.toList(),
  '대촌70_UP': _daechon70_UP, '대촌70_DOWN': _daechon70_UP.reversed.toList(),
  '대촌71_UP': _daechon71_UP, '대촌71_DOWN': _daechon71_UP.reversed.toList(),
  '송암72_UP': _songam72_UP, '송암72_DOWN': _songam72_UP.reversed.toList(),
  '송암73_UP': _songam73_UP, '송암73_DOWN': _songam73_UP.reversed.toList(),
  '송암74_UP': _songam74_UP, '송암74_DOWN': _songam74_UP.reversed.toList(),
  '봉선76_UP': _bongseon76_UP, '봉선76_DOWN': _bongseon76_UP.reversed.toList(),
  '진월77_UP': _jinwol77_UP, '진월77_DOWN': _jinwol77_UP.reversed.toList(),
  '진월78_UP': _jinwol78_UP, '진월78_DOWN': _jinwol78_UP.reversed.toList(),
  '문흥80_UP': _munheung80_UP, '문흥80_DOWN': _munheung80_UP.reversed.toList(),
  '두암81_UP': _duam81_UP, '두암81_DOWN': _duam81_UP.reversed.toList(),
  '용봉83_UP': _yongbong83_UP, '용봉83_DOWN': _yongbong83_UP.reversed.toList(),
  '용전84_UP': _yongjeon84_UP, '용전84_DOWN': _yongjeon84_UP.reversed.toList(),
  '용전85_UP': _yongjeon85_UP, '용전85_DOWN': _yongjeon85_UP.reversed.toList(),
  '용전86_UP': _yongjeon86_UP, '용전86_DOWN': _yongjeon86_UP.reversed.toList(),
  '석곡87_UP': _seokgok87_UP, '석곡87_DOWN': _seokgok87_UP.reversed.toList(),
  '임곡89_UP': _imgok89_UP, '임곡89_DOWN': _imgok89_UP.reversed.toList(),
  '임곡90_UP': _imgok90_UP, '임곡90_DOWN': _imgok90_UP.reversed.toList(),
  '임곡91_UP': _imgok91_UP, '임곡91_DOWN': _imgok91_UP.reversed.toList(),
  '송정93_UP': _songjeong93_UP, '송정93_DOWN': _songjeong93_UP.reversed.toList(),
  '첨단95_UP': _cheomdan95_UP, '첨단95_DOWN': _cheomdan95_UP.reversed.toList(),
  '송정96_UP': _songjeong96_UP, '송정96_DOWN': _songjeong96_UP.reversed.toList(),
  '송정97_UP': _songjeong97_UP, '송정97_DOWN': _songjeong97_UP.reversed.toList(),
  '송정98_UP': _songjeong98_UP, '송정98_DOWN': _songjeong98_UP.reversed.toList(),
};

final Map<String, Map<String, dynamic>> part2Details = {
  '운림54': { 'LINE_NAME': '운림54', 'FIRST_RUN': '05:50', 'LAST_RUN': '22:45', 'INTERVAL': '15', 'DIR_UP_NAME': '동림동', 'DIR_DOWN_NAME': '증심사' },
  '금남55': { 'LINE_NAME': '금남55', 'FIRST_RUN': '06:00', 'LAST_RUN': '22:00', 'INTERVAL': '22', 'DIR_UP_NAME': '장등동', 'DIR_DOWN_NAME': '덕남' },
  '금남57': { 'LINE_NAME': '금남57', 'FIRST_RUN': '05:45', 'LAST_RUN': '22:30', 'INTERVAL': '18', 'DIR_UP_NAME': '살레시오고', 'DIR_DOWN_NAME': '장등동' },
  '금남58': { 'LINE_NAME': '금남58', 'FIRST_RUN': '05:40', 'LAST_RUN': '23:00', 'INTERVAL': '13', 'DIR_UP_NAME': '문화전당', 'DIR_DOWN_NAME': '동림삼익' },
  '금남59': { 'LINE_NAME': '금남59', 'FIRST_RUN': '05:40', 'LAST_RUN': '22:30', 'INTERVAL': '15', 'DIR_UP_NAME': '장등동', 'DIR_DOWN_NAME': '도산동' },
  '양산60': { 'LINE_NAME': '양산60', 'FIRST_RUN': '06:10', 'LAST_RUN': '22:00', 'INTERVAL': '25', 'DIR_UP_NAME': '광주역', 'DIR_DOWN_NAME': '양산' },
  '매월61': { 'LINE_NAME': '매월61', 'FIRST_RUN': '06:00', 'LAST_RUN': '22:00', 'INTERVAL': '20', 'DIR_UP_NAME': '조선대', 'DIR_DOWN_NAME': '칠석' },
  '상무62': { 'LINE_NAME': '상무62', 'FIRST_RUN': '05:50', 'LAST_RUN': '22:30', 'INTERVAL': '20', 'DIR_UP_NAME': '첨단', 'DIR_DOWN_NAME': '상무지구' },
  '상무63': { 'LINE_NAME': '상무63', 'FIRST_RUN': '06:00', 'LAST_RUN': '22:15', 'INTERVAL': '25', 'DIR_UP_NAME': '광주역', 'DIR_DOWN_NAME': '상무지구' },
  '상무64': { 'LINE_NAME': '상무64', 'FIRST_RUN': '06:00', 'LAST_RUN': '22:30', 'INTERVAL': '20', 'DIR_UP_NAME': '백운광장', 'DIR_DOWN_NAME': '상무지구' },
  '유덕65': { 'LINE_NAME': '유덕65', 'FIRST_RUN': '06:15', 'LAST_RUN': '22:00', 'INTERVAL': '28', 'DIR_UP_NAME': '광주역', 'DIR_DOWN_NAME': '유덕' },
  '송암68': { 'LINE_NAME': '송암68', 'FIRST_RUN': '06:00', 'LAST_RUN': '22:20', 'INTERVAL': '22', 'DIR_UP_NAME': '장등동', 'DIR_DOWN_NAME': '송암' },
  '대촌69': { 'LINE_NAME': '대촌69', 'FIRST_RUN': '06:20', 'LAST_RUN': '21:50', 'INTERVAL': '35', 'DIR_UP_NAME': '광주역', 'DIR_DOWN_NAME': '대촌' },
  '대촌70': { 'LINE_NAME': '대촌70', 'FIRST_RUN': '06:00', 'LAST_RUN': '22:00', 'INTERVAL': '30', 'DIR_UP_NAME': '롯데백화점', 'DIR_DOWN_NAME': '승촌보' },
  '대촌71': { 'LINE_NAME': '대촌71', 'FIRST_RUN': '06:30', 'LAST_RUN': '21:40', 'INTERVAL': '40', 'DIR_UP_NAME': '광주역', 'DIR_DOWN_NAME': '대촌' },
  '송암72': { 'LINE_NAME': '송암72', 'FIRST_RUN': '05:45', 'LAST_RUN': '22:30', 'INTERVAL': '16', 'DIR_UP_NAME': '장등동', 'DIR_DOWN_NAME': '송암공단' },
  '송암73': { 'LINE_NAME': '송암73', 'FIRST_RUN': '06:10', 'LAST_RUN': '22:00', 'INTERVAL': '30', 'DIR_UP_NAME': '시청', 'DIR_DOWN_NAME': '송암' },
  '송암74': { 'LINE_NAME': '송암74', 'FIRST_RUN': '05:50', 'LAST_RUN': '22:20', 'INTERVAL': '20', 'DIR_UP_NAME': '시청', 'DIR_DOWN_NAME': '송암공단' },
  '봉선76': { 'LINE_NAME': '봉선76', 'FIRST_RUN': '06:15', 'LAST_RUN': '22:00', 'INTERVAL': '28', 'DIR_UP_NAME': '조선대', 'DIR_DOWN_NAME': '봉선' },
  '진월77': { 'LINE_NAME': '진월77', 'FIRST_RUN': '06:00', 'LAST_RUN': '22:10', 'INTERVAL': '22', 'DIR_UP_NAME': '동명동', 'DIR_DOWN_NAME': '송암공단' },
  '진월78': { 'LINE_NAME': '진월78', 'FIRST_RUN': '06:10', 'LAST_RUN': '22:00', 'INTERVAL': '25', 'DIR_UP_NAME': '송암', 'DIR_DOWN_NAME': '진월' },
  '문흥80': { 'LINE_NAME': '문흥80', 'FIRST_RUN': '05:55', 'LAST_RUN': '22:25', 'INTERVAL': '18', 'DIR_UP_NAME': '장등동', 'DIR_DOWN_NAME': '문흥' },
  '두암81': { 'LINE_NAME': '두암81', 'FIRST_RUN': '06:20', 'LAST_RUN': '21:50', 'INTERVAL': '32', 'DIR_UP_NAME': '광주역', 'DIR_DOWN_NAME': '두암' },
  '용봉83': { 'LINE_NAME': '용봉83', 'FIRST_RUN': '06:00', 'LAST_RUN': '22:30', 'INTERVAL': '20', 'DIR_UP_NAME': '비엔날레', 'DIR_DOWN_NAME': '장등동' },
  '용전84': { 'LINE_NAME': '용전84', 'FIRST_RUN': '06:30', 'LAST_RUN': '21:40', 'INTERVAL': '45', 'DIR_UP_NAME': '광주역', 'DIR_DOWN_NAME': '용전' },
  '용전85': { 'LINE_NAME': '용전85', 'FIRST_RUN': '06:40', 'LAST_RUN': '21:30', 'INTERVAL': '50', 'DIR_UP_NAME': '광주역', 'DIR_DOWN_NAME': '용전' },
  '용전86': { 'LINE_NAME': '용전86', 'FIRST_RUN': '06:50', 'LAST_RUN': '21:20', 'INTERVAL': '55', 'DIR_UP_NAME': '광주역', 'DIR_DOWN_NAME': '용전' },
  '석곡87': { 'LINE_NAME': '석곡87', 'FIRST_RUN': '06:10', 'LAST_RUN': '22:00', 'INTERVAL': '25', 'DIR_UP_NAME': '조선대', 'DIR_DOWN_NAME': '장등동' },
  '임곡89': { 'LINE_NAME': '임곡89', 'FIRST_RUN': '06:00', 'LAST_RUN': '21:30', 'INTERVAL': '45', 'DIR_UP_NAME': '광주역', 'DIR_DOWN_NAME': '임곡역' },
  '임곡90': { 'LINE_NAME': '임곡90', 'FIRST_RUN': '07:00', 'LAST_RUN': '21:00', 'INTERVAL': '60', 'DIR_UP_NAME': '비아', 'DIR_DOWN_NAME': '임곡' },
  '임곡91': { 'LINE_NAME': '임곡91', 'FIRST_RUN': '07:10', 'LAST_RUN': '20:50', 'INTERVAL': '65', 'DIR_UP_NAME': '비아', 'DIR_DOWN_NAME': '임곡' },
  '송정93': { 'LINE_NAME': '송정93', 'FIRST_RUN': '06:30', 'LAST_RUN': '21:40', 'INTERVAL': '42', 'DIR_UP_NAME': '도산동', 'DIR_DOWN_NAME': '본촌' },
  '첨단95': { 'LINE_NAME': '첨단95', 'FIRST_RUN': '05:45', 'LAST_RUN': '22:30', 'INTERVAL': '18', 'DIR_UP_NAME': '시청', 'DIR_DOWN_NAME': '첨단' },
  '송정96': { 'LINE_NAME': '송정96', 'FIRST_RUN': '06:40', 'LAST_RUN': '21:30', 'INTERVAL': '48', 'DIR_UP_NAME': '도산동', 'DIR_DOWN_NAME': '본촌' },
  '송정97': { 'LINE_NAME': '송정97', 'FIRST_RUN': '06:00', 'LAST_RUN': '22:00', 'INTERVAL': '22', 'DIR_UP_NAME': '백운광장', 'DIR_DOWN_NAME': '도산동' },
  '송정98': { 'LINE_NAME': '송정98', 'FIRST_RUN': '05:40', 'LAST_RUN': '22:30', 'INTERVAL': '15', 'DIR_UP_NAME': '용봉초교', 'DIR_DOWN_NAME': '도산동' },
};

// ── 데이터 생성 (파트 2) ──

final _unlim54_UP = generateStations(firstRun: '05:50', lastRun: '22:45', raw: [
  {'name': '증심사', 'id': '2405', 'lat': 35.1245, 'lng': 126.9555},
  {'name': '학동증심사입구역', 'id': '2005', 'lat': 35.1315, 'lng': 126.9315},
  {'name': '조선대', 'id': '2050', 'lat': 35.1417, 'lng': 126.9355},
  {'name': '전남대병원', 'id': '2010', 'lat': 35.1425, 'lng': 126.9225},
  {'name': '양동시장', 'id': '2005', 'lat': 35.1562, 'lng': 126.9055},
  {'name': '동림동', 'id': '4001', 'lat': 35.1773, 'lng': 126.8655},
]);

final _geumnam55_UP = generateStations(firstRun: '06:00', lastRun: '22:00', raw: [
  {'name': '장등동', 'id': '4501', 'lat': 35.1925, 'lng': 126.9655},
  {'name': '말바우시장', 'id': '2105', 'lat': 35.1685, 'lng': 126.9255},
  {'name': '대인시장', 'id': '2010', 'lat': 35.1555, 'lng': 126.9205},
  {'name': '문화전당', 'id': '2020', 'lat': 35.1486, 'lng': 126.9235},
  {'name': '백운광장', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
  {'name': '덕남', 'id': '2550', 'lat': 35.1055, 'lng': 126.9055},
]);

final _geumnam57_UP = generateStations(firstRun: '05:45', lastRun: '22:30', raw: [
  {'name': '살레시오고', 'id': '2350', 'lat': 35.2125, 'lng': 126.9055},
  {'name': '일곡지구', 'id': '2301', 'lat': 35.2015, 'lng': 126.8955},
  {'name': '전남대후문', 'id': '2105', 'lat': 35.1754, 'lng': 126.9155},
  {'name': '장등동', 'id': '4501', 'lat': 35.1925, 'lng': 126.9655},
]);

final _geumnam58_UP = generateStations(firstRun: '05:40', lastRun: '23:00', raw: [
  {'name': '문화전당', 'id': '2020', 'lat': 35.1486, 'lng': 126.9235},
  {'name': '광천터미널', 'id': '1105', 'lat': 35.1605, 'lng': 126.8815},
  {'name': '동림삼익', 'id': '4005', 'lat': 35.1855, 'lng': 126.8655},
]);

final _geumnam59_UP = generateStations(firstRun: '05:40', lastRun: '22:30', raw: [
  {'name': '장등동', 'id': '4501', 'lat': 35.1925, 'lng': 126.9655},
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '도산동', 'id': '5501', 'lat': 35.1287, 'lng': 126.7855},
]);

final _yangsan60_UP = generateStations(firstRun: '06:10', lastRun: '22:00', raw: [
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '양산', 'id': '4301', 'lat': 35.2055, 'lng': 126.8755},
]);

final _maewol61_UP = generateStations(firstRun: '06:00', lastRun: '22:00', raw: [
  {'name': '조선대', 'id': '2050', 'lat': 35.1417, 'lng': 126.9355},
  {'name': '칠석', 'id': '3155', 'lat': 35.0855, 'lng': 126.8555},
]);

final _sangmu62_UP = generateStations(firstRun: '05:50', lastRun: '22:30', raw: [
  {'name': '첨단', 'id': '5014', 'lat': 35.2107, 'lng': 126.8407},
  {'name': '상무지구', 'id': '1001', 'lat': 35.1492, 'lng': 126.8515},
]);

final _sangmu63_UP = generateStations(firstRun: '06:00', lastRun: '22:15', raw: [
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '상무지구', 'id': '1001', 'lat': 35.1492, 'lng': 126.8515},
]);

final _sangmu64_UP = generateStations(firstRun: '06:00', lastRun: '22:30', raw: [
  {'name': '백운광장', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
  {'name': '상무지구', 'id': '1001', 'lat': 35.1492, 'lng': 126.8515},
]);

final _yudeok65_UP = generateStations(firstRun: '06:15', lastRun: '22:00', raw: [
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '유덕', 'id': '1115', 'lat': 35.1655, 'lng': 126.8555},
]);

final _songam68_UP = generateStations(firstRun: '06:00', lastRun: '22:20', raw: [
  {'name': '장등동', 'id': '4501', 'lat': 35.1925, 'lng': 126.9655},
  {'name': '송암', 'id': '3101', 'lat': 35.1115, 'lng': 126.8755},
]);

final _daechon69_UP = generateStations(firstRun: '06:20', lastRun: '21:50', raw: [
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '대촌', 'id': '3160', 'lat': 35.0955, 'lng': 126.8455},
]);

final _daechon70_UP = generateStations(firstRun: '06:00', lastRun: '22:00', raw: [
  {'name': '롯데백화점', 'id': '2001', 'lat': 35.1555, 'lng': 126.9155},
  {'name': '승촌보', 'id': '3170', 'lat': 35.0755, 'lng': 126.8155},
]);

final _daechon71_UP = generateStations(firstRun: '06:30', lastRun: '21:40', raw: [
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '대촌', 'id': '3160', 'lat': 35.0955, 'lng': 126.8455},
]);

final _songam72_UP = generateStations(firstRun: '05:45', lastRun: '22:30', raw: [
  {'name': '장등동', 'id': '4501', 'lat': 35.1925, 'lng': 126.9655},
  {'name': '송암공단', 'id': '3101', 'lat': 35.1115, 'lng': 126.8755},
]);

final _songam73_UP = generateStations(firstRun: '06:10', lastRun: '22:00', raw: [
  {'name': '시청', 'id': '1001', 'lat': 35.1589, 'lng': 126.8515},
  {'name': '송암', 'id': '3101', 'lat': 35.1115, 'lng': 126.8755},
]);

final _songam74_UP = generateStations(firstRun: '05:50', lastRun: '22:20', raw: [
  {'name': '시청', 'id': '1001', 'lat': 35.1589, 'lng': 126.8515},
  {'name': '송암공단', 'id': '3101', 'lat': 35.1115, 'lng': 126.8755},
]);

final _bongseon76_UP = generateStations(firstRun: '06:15', lastRun: '22:00', raw: [
  {'name': '조선대', 'id': '2050', 'lat': 35.1417, 'lng': 126.9355},
  {'name': '봉선', 'id': '3301', 'lat': 35.1282, 'lng': 126.9255},
]);

final _jinwol77_UP = generateStations(firstRun: '06:00', lastRun: '22:10', raw: [
  {'name': '동명동', 'id': '2030', 'lat': 35.1525, 'lng': 126.9255},
  {'name': '송암공단', 'id': '3101', 'lat': 35.1115, 'lng': 126.8755},
]);

final _jinwol78_UP = generateStations(firstRun: '06:10', lastRun: '22:00', raw: [
  {'name': '송암', 'id': '3101', 'lat': 35.1115, 'lng': 126.8755},
  {'name': '진월', 'id': '3010', 'lat': 35.1242, 'lng': 126.9055},
]);

final _munheung80_UP = generateStations(firstRun: '05:55', lastRun: '22:25', raw: [
  {'name': '장등동', 'id': '4501', 'lat': 35.1925, 'lng': 126.9655},
  {'name': '문흥', 'id': '2201', 'lat': 35.1852, 'lng': 126.9355},
]);

final _duam81_UP = generateStations(firstRun: '06:20', lastRun: '21:50', raw: [
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '두암', 'id': '2250', 'lat': 35.1655, 'lng': 126.9455},
]);

final _yongbong83_UP = generateStations(firstRun: '06:00', lastRun: '22:30', raw: [
  {'name': '비엔날레', 'id': '4101', 'lat': 35.1855, 'lng': 126.8955},
  {'name': '장등동', 'id': '4501', 'lat': 35.1925, 'lng': 126.9655},
]);

final _yongjeon84_UP = generateStations(firstRun: '06:30', lastRun: '21:40', raw: [
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '용전', 'id': '2390', 'lat': 35.2252, 'lng': 126.9055},
]);

final _yongjeon85_UP = generateStations(firstRun: '06:40', lastRun: '21:30', raw: [
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '용전', 'id': '2390', 'lat': 35.2252, 'lng': 126.9055},
]);

final _yongjeon86_UP = generateStations(firstRun: '06:50', lastRun: '21:20', raw: [
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '용전', 'id': '2390', 'lat': 35.2252, 'lng': 126.9055},
]);

final _seokgok87_UP = generateStations(firstRun: '06:10', lastRun: '22:00', raw: [
  {'name': '조선대', 'id': '2050', 'lat': 35.1417, 'lng': 126.9355},
  {'name': '장등동', 'id': '4501', 'lat': 35.1925, 'lng': 126.9655},
]);

final _imgok89_UP = generateStations(firstRun: '06:00', lastRun: '21:30', raw: [
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '임곡역', 'id': '5350', 'lat': 35.1955, 'lng': 126.7455},
]);

final _imgok90_UP = generateStations(firstRun: '07:00', lastRun: '21:00', raw: [
  {'name': '비아', 'id': '5301', 'lat': 35.2155, 'lng': 126.8255},
  {'name': '임곡', 'id': '5350', 'lat': 35.1955, 'lng': 126.7455},
]);

final _imgok91_UP = generateStations(firstRun: '07:10', lastRun: '20:50', raw: [
  {'name': '비아', 'id': '5301', 'lat': 35.2155, 'lng': 126.8255},
  {'name': '임곡', 'id': '5350', 'lat': 35.1955, 'lng': 126.7455},
]);

final _songjeong93_UP = generateStations(firstRun: '06:30', lastRun: '21:40', raw: [
  {'name': '도산동', 'id': '5501', 'lat': 35.1287, 'lng': 126.7855},
  {'name': '본촌', 'id': '4350', 'lat': 35.2155, 'lng': 126.8855},
]);

final _cheomdan95_UP = generateStations(firstRun: '05:45', lastRun: '22:30', raw: [
  {'name': '시청', 'id': '1001', 'lat': 35.1589, 'lng': 126.8515},
  {'name': '첨단', 'id': '5014', 'lat': 35.2107, 'lng': 126.8407},
]);

final _songjeong96_UP = generateStations(firstRun: '06:40', lastRun: '21:30', raw: [
  {'name': '도산동', 'id': '5501', 'lat': 35.1287, 'lng': 126.7855},
  {'name': '본촌', 'id': '4350', 'lat': 35.2155, 'lng': 126.8855},
]);

final _songjeong97_UP = generateStations(firstRun: '06:00', lastRun: '22:00', raw: [
  {'name': '백운광장', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
  {'name': '도산동', 'id': '5501', 'lat': 35.1287, 'lng': 126.7855},
]);

final _songjeong98_UP = generateStations(firstRun: '05:40', lastRun: '22:30', raw: [
  {'name': '용봉초교', 'id': '2106', 'lat': 35.1784, 'lng': 126.9135},
  {'name': '도산동', 'id': '5501', 'lat': 35.1287, 'lng': 126.7855},
]);
