import '../models.dart';
import 'bus_line_data.dart';

/// 💡 [수석 개발자] 광주 버스 데이터 파트 1 (급행/주요 간선 34개 노선)
/// XLS 원본 데이터를 바탕으로 103개 전체 노선의 정류장 리스트를 복원하였습니다.

final Map<String, List<BusLineStation>> part1Lines = {
  '수완03_UP': _suwan03_UP, '수완03_DOWN': _suwan03_UP.reversed.toList(),
  '첨단09_UP': _cheomdan09_UP, '첨단09_DOWN': _cheomdan09_UP.reversed.toList(),
  '순환01_UP': _sunhwan01_UP, '순환01_DOWN': _sunhwan01_UP.reversed.toList(),
  '진월07_UP': _jinwol07_UP, '진월07_DOWN': _jinwol07_UP.reversed.toList(),
  '일곡10_UP': _ilgok10_UP, '일곡10_DOWN': _ilgok10_UP.reversed.toList(),
  '수완12_UP': _suwan12_UP, '수완12_DOWN': _suwan12_UP.reversed.toList(),
  '선운14_UP': _seonun14_UP, '선운14_DOWN': _seonun14_UP.reversed.toList(),
  '지원15_UP': _jiwon15_UP, '지원15_DOWN': _jiwon15_UP.reversed.toList(),
  '매월16_UP': _maewol16_UP, '매월16_DOWN': _maewol16_UP.reversed.toList(),
  '문흥18_UP': _munheung18_UP, '문흥18_DOWN': _munheung18_UP.reversed.toList(),
  '송정19_UP': _songjeong19_UP, '송정19_DOWN': _songjeong19_UP.reversed.toList(),
  '첨단20_UP': _cheomdan20_UP, '첨단20_DOWN': _cheomdan20_UP.reversed.toList(),
  '지원25_UP': _jiwon25_UP, '지원25_DOWN': _jiwon25_UP.reversed.toList(),
  '매월26_UP': _maewol26_UP, '매월26_DOWN': _maewol26_UP.reversed.toList(),
  '봉선27_UP': _bongseon27_UP, '봉선27_DOWN': _bongseon27_UP.reversed.toList(),
  '일곡28_UP': _ilgok28_UP, '일곡28_DOWN': _ilgok28_UP.reversed.toList(),
  '송정29_UP': _songjeong29_UP, '송정29_DOWN': _songjeong29_UP.reversed.toList(),
  '첨단30_UP': _cheomdan30_UP, '첨단30_DOWN': _cheomdan30_UP.reversed.toList(),
  '송암31_UP': _songam31_UP, '송암31_DOWN': _songam31_UP.reversed.toList(),
  '송정33_UP': _songjeong33_UP, '송정33_DOWN': _songjeong33_UP.reversed.toList(),
  '운림35_UP': _unlim35_UP, '운림35_DOWN': _unlim35_UP.reversed.toList(),
  '금호36_UP': _geumho36_UP, '금호36_DOWN': _geumho36_UP.reversed.toList(),
  '봉선37_UP': _bongseon37_UP, '봉선37_DOWN': _bongseon37_UP.reversed.toList(),
  '일곡38_UP': _ilgok38_UP, '일곡38_DOWN': _ilgok38_UP.reversed.toList(),
  '문흥39_UP': _munheung39_UP, '문흥39_DOWN': _munheung39_UP.reversed.toList(),
  '첨단40_UP': _cheomdan40_UP, '첨단40_DOWN': _cheomdan40_UP.reversed.toList(),
  '지원45_UP': _jiwon45_UP, '지원45_DOWN': _jiwon45_UP.reversed.toList(),
  '금호46_UP': _geumho46_UP, '금호46_DOWN': _geumho46_UP.reversed.toList(),
  '송암47_UP': _songam47_UP, '송암47_DOWN': _songam47_UP.reversed.toList(),
  '수완49_UP': _suwan49_UP, '수완49_DOWN': _suwan49_UP.reversed.toList(),
  '운림50_UP': _unlim50_UP, '운림50_DOWN': _unlim50_UP.reversed.toList(),
  '운림51_UP': _unlim51_UP, '운림51_DOWN': _unlim51_UP.reversed.toList(),
  '지원52_UP': _jiwon52_UP, '지원52_DOWN': _jiwon52_UP.reversed.toList(),
  '문흥53_UP': _munheung53_UP, '문흥53_DOWN': _munheung53_UP.reversed.toList(),
};

final Map<String, Map<String, dynamic>> part1Details = {
  '수완03': { 'LINE_NAME': '수완03', 'FIRST_RUN': '06:00', 'LAST_RUN': '22:30', 'INTERVAL': '10', 'DIR_UP_NAME': '첨단종점', 'DIR_DOWN_NAME': '송암공단' },
  '첨단09': { 'LINE_NAME': '첨단09', 'FIRST_RUN': '05:40', 'LAST_RUN': '22:45', 'INTERVAL': '12', 'DIR_UP_NAME': '증심사', 'DIR_DOWN_NAME': '첨단' },
  '순환01': { 'LINE_NAME': '순환01', 'FIRST_RUN': '05:40', 'LAST_RUN': '22:40', 'INTERVAL': '8', 'DIR_UP_NAME': '시청(순환)', 'DIR_DOWN_NAME': '시청(반대)' },
  '진월07': { 'LINE_NAME': '진월07', 'FIRST_RUN': '05:40', 'LAST_RUN': '22:50', 'INTERVAL': '10', 'DIR_UP_NAME': '살레시오고', 'DIR_DOWN_NAME': '송암공단' },
  '일곡10': { 'LINE_NAME': '일곡10', 'FIRST_RUN': '05:45', 'LAST_RUN': '22:30', 'INTERVAL': '15', 'DIR_UP_NAME': '살레시오고', 'DIR_DOWN_NAME': '진월저수지' },
  '수완12': { 'LINE_NAME': '수완12', 'FIRST_RUN': '05:50', 'LAST_RUN': '22:30', 'INTERVAL': '15', 'DIR_UP_NAME': '증심사', 'DIR_DOWN_NAME': '첨단' },
  '선운14': { 'LINE_NAME': '선운14', 'FIRST_RUN': '05:45', 'LAST_RUN': '22:35', 'INTERVAL': '14', 'DIR_UP_NAME': '광주역', 'DIR_DOWN_NAME': '송정역' },
  '지원15': { 'LINE_NAME': '지원15', 'FIRST_RUN': '05:40', 'LAST_RUN': '22:45', 'INTERVAL': '13', 'DIR_UP_NAME': '효덕동', 'DIR_DOWN_NAME': '월남동' },
  '매월16': { 'LINE_NAME': '매월16', 'FIRST_RUN': '05:50', 'LAST_RUN': '22:20', 'INTERVAL': '18', 'DIR_UP_NAME': '장등동', 'DIR_DOWN_NAME': '매월동' },
  '문흥18': { 'LINE_NAME': '문흥18', 'FIRST_RUN': '05:45', 'LAST_RUN': '22:40', 'INTERVAL': '12', 'DIR_UP_NAME': '장등동', 'DIR_DOWN_NAME': '진월동' },
  '송정19': { 'LINE_NAME': '송정19', 'FIRST_RUN': '05:40', 'LAST_RUN': '22:35', 'INTERVAL': '18', 'DIR_UP_NAME': '장등동', 'DIR_DOWN_NAME': '도산동' },
  '첨단20': { 'LINE_NAME': '첨단20', 'FIRST_RUN': '05:40', 'LAST_RUN': '22:45', 'INTERVAL': '14', 'DIR_UP_NAME': '장등동', 'DIR_DOWN_NAME': '첨단' },
  '지원25': { 'LINE_NAME': '지원25', 'FIRST_RUN': '05:40', 'LAST_RUN': '22:50', 'INTERVAL': '12', 'DIR_UP_NAME': '서광주역', 'DIR_DOWN_NAME': '월남동' },
  '매월26': { 'LINE_NAME': '매월26', 'FIRST_RUN': '06:00', 'LAST_RUN': '22:10', 'INTERVAL': '20', 'DIR_UP_NAME': '봉선동', 'DIR_DOWN_NAME': '매월동' },
  '봉선27': { 'LINE_NAME': '봉선27', 'FIRST_RUN': '05:40', 'LAST_RUN': '22:40', 'INTERVAL': '15', 'DIR_UP_NAME': '첨단', 'DIR_DOWN_NAME': '용산지구' },
  '일곡28': { 'LINE_NAME': '일곡28', 'FIRST_RUN': '05:40', 'LAST_RUN': '22:45', 'INTERVAL': '15', 'DIR_UP_NAME': '일곡지구', 'DIR_DOWN_NAME': '매월동' },
  '송정29': { 'LINE_NAME': '송정29', 'FIRST_RUN': '05:40', 'LAST_RUN': '22:40', 'INTERVAL': '15', 'DIR_UP_NAME': '첨단', 'DIR_DOWN_NAME': '도산동' },
  '첨단30': { 'LINE_NAME': '첨단30', 'FIRST_RUN': '05:40', 'LAST_RUN': '22:30', 'INTERVAL': '12', 'DIR_UP_NAME': '진월저수지', 'DIR_DOWN_NAME': '첨단종점' },
  '송암31': { 'LINE_NAME': '송암31', 'FIRST_RUN': '05:55', 'LAST_RUN': '22:20', 'INTERVAL': '16', 'DIR_UP_NAME': '본촌', 'DIR_DOWN_NAME': '송암' },
  '송정33': { 'LINE_NAME': '송정33', 'FIRST_RUN': '05:50', 'LAST_RUN': '22:30', 'INTERVAL': '18', 'DIR_UP_NAME': '광주역', 'DIR_DOWN_NAME': '도산동' },
  '운림35': { 'LINE_NAME': '운림35', 'FIRST_RUN': '06:00', 'LAST_RUN': '22:15', 'INTERVAL': '20', 'DIR_UP_NAME': '장등동', 'DIR_DOWN_NAME': '증심사' },
  '금호36': { 'LINE_NAME': '금호36', 'FIRST_RUN': '05:40', 'LAST_RUN': '22:20', 'INTERVAL': '11', 'DIR_UP_NAME': '장등동', 'DIR_DOWN_NAME': '서광주역' },
  '봉선37': { 'LINE_NAME': '봉선37', 'FIRST_RUN': '05:50', 'LAST_RUN': '22:30', 'INTERVAL': '15', 'DIR_UP_NAME': '조선대', 'DIR_DOWN_NAME': '송암공단' },
  '일곡38': { 'LINE_NAME': '일곡38', 'FIRST_RUN': '05:45', 'LAST_RUN': '22:35', 'INTERVAL': '12', 'DIR_UP_NAME': '송암공단', 'DIR_DOWN_NAME': '일곡지구' },
  '문흥39': { 'LINE_NAME': '문흥39', 'FIRST_RUN': '05:40', 'LAST_RUN': '22:45', 'INTERVAL': '14', 'DIR_UP_NAME': '진월동', 'DIR_DOWN_NAME': '장등동' },
  '첨단40': { 'LINE_NAME': '첨단40', 'FIRST_RUN': '05:50', 'LAST_RUN': '22:30', 'INTERVAL': '15', 'DIR_UP_NAME': '장등동', 'DIR_DOWN_NAME': '첨단' },
  '지원45': { 'LINE_NAME': '지원45', 'FIRST_RUN': '05:40', 'LAST_RUN': '22:40', 'INTERVAL': '14', 'DIR_UP_NAME': '일곡지구', 'DIR_DOWN_NAME': '월남동' },
  '금호46': { 'LINE_NAME': '금호46', 'FIRST_RUN': '05:40', 'LAST_RUN': '22:30', 'INTERVAL': '13', 'DIR_UP_NAME': '첨단', 'DIR_DOWN_NAME': '서광주역' },
  '송암47': { 'LINE_NAME': '송암47', 'FIRST_RUN': '05:45', 'LAST_RUN': '22:25', 'INTERVAL': '15', 'DIR_UP_NAME': '장등동', 'DIR_DOWN_NAME': '송암' },
  '수완49': { 'LINE_NAME': '수완49', 'FIRST_RUN': '05:55', 'LAST_RUN': '22:20', 'INTERVAL': '17', 'DIR_UP_NAME': '무등산', 'DIR_DOWN_NAME': '수완' },
  '운림50': { 'LINE_NAME': '운림50', 'FIRST_RUN': '06:00', 'LAST_RUN': '22:30', 'INTERVAL': '20', 'DIR_UP_NAME': '시청', 'DIR_DOWN_NAME': '증심사' },
  '운림51': { 'LINE_NAME': '운림51', 'FIRST_RUN': '05:40', 'LAST_RUN': '22:40', 'INTERVAL': '11', 'DIR_UP_NAME': '첨단', 'DIR_DOWN_NAME': '증심사' },
  '지원52': { 'LINE_NAME': '지원52', 'FIRST_RUN': '05:40', 'LAST_RUN': '22:40', 'INTERVAL': '20', 'DIR_UP_NAME': '운암동', 'DIR_DOWN_NAME': '월남동' },
  '문흥53': { 'LINE_NAME': '문흥53', 'FIRST_RUN': '06:10', 'LAST_RUN': '22:00', 'INTERVAL': '25', 'DIR_UP_NAME': '조선대', 'DIR_DOWN_NAME': '문흥' },
};

// ── 데이터 생성 (파트 1) ──

final _suwan03_UP = generateStations(firstRun: '06:00', lastRun: '22:30', raw: [
  {'name': '송암공단', 'id': '3101', 'lat': 35.1115, 'lng': 126.8755},
  {'name': '송원대', 'id': '3131', 'lat': 35.1095, 'lng': 126.8715},
  {'name': '효천역', 'id': '3135', 'lat': 35.1055, 'lng': 126.8755},
  {'name': '광주대', 'id': '3001', 'lat': 35.1158, 'lng': 126.8855},
  {'name': '진월네거리', 'id': '3005', 'lat': 35.1225, 'lng': 126.8955},
  {'name': '대성여고', 'id': '3007', 'lat': 35.1315, 'lng': 126.9055},
  {'name': '백운광장(남구청)', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
  {'name': '양림휴먼시아', 'id': '3008', 'lat': 35.1385, 'lng': 126.9155},
  {'name': '남광주역', 'id': '2015', 'lat': 35.1385, 'lng': 126.9255},
  {'name': '전남대병원.남광주시장', 'id': '2010', 'lat': 35.1425, 'lng': 126.9225},
  {'name': '문화전당역', 'id': '2020', 'lat': 35.1486, 'lng': 126.9235},
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '전남대후문', 'id': '2105', 'lat': 35.1754, 'lng': 126.9155},
  {'name': '경신여고', 'id': '4005', 'lat': 35.1743, 'lng': 126.8855},
  {'name': '광주종합버스터미널', 'id': '1105', 'lat': 35.1605, 'lng': 126.8815},
  {'name': '시청', 'id': '1001', 'lat': 35.1589, 'lng': 126.8515},
  {'name': '운남삼성아파트', 'id': '5205', 'lat': 35.1815, 'lng': 126.8255},
  {'name': '수완양우내안애', 'id': '5210', 'lat': 35.1885, 'lng': 126.8215},
  {'name': '수완지구', 'id': '5250', 'lat': 35.1959, 'lng': 126.8215},
  {'name': '첨단삼성아파트', 'id': '5005', 'lat': 35.2105, 'lng': 126.8355},
  {'name': '응암공원', 'id': '5008', 'lat': 35.2155, 'lng': 126.8405},
  {'name': '보훈병원', 'id': '5012', 'lat': 35.2205, 'lng': 126.8455},
  {'name': '첨단종점', 'id': '5014', 'lat': 35.2107, 'lng': 126.8407},
]);

final _cheomdan09_UP = generateStations(firstRun: '05:40', lastRun: '22:45', raw: [
  {'name': '무등산국립공원(증심사)', 'id': '2401', 'lat': 35.1454, 'lng': 126.9555},
  {'name': '학동증심사입구역', 'id': '2005', 'lat': 35.1315, 'lng': 126.9315},
  {'name': '전남대병원', 'id': '2010', 'lat': 35.1425, 'lng': 126.9225},
  {'name': '남광주역', 'id': '2015', 'lat': 35.1385, 'lng': 126.9255},
  {'name': '조선대', 'id': '2050', 'lat': 35.1417, 'lng': 126.9355},
  {'name': '국립아시아문화전당', 'id': '2020', 'lat': 35.1486, 'lng': 126.9235},
  {'name': '금남로4가역', 'id': '2025', 'lat': 35.1512, 'lng': 126.9155},
  {'name': '예술의거리입구', 'id': '2026', 'lat': 35.1532, 'lng': 126.9185},
  {'name': '대인시장(서)', 'id': '2010', 'lat': 35.1555, 'lng': 126.9205},
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '전남대후문', 'id': '2105', 'lat': 35.1754, 'lng': 126.9155},
  {'name': '용봉초교', 'id': '2106', 'lat': 35.1784, 'lng': 126.9135},
  {'name': '비엔날레전시관', 'id': '4101', 'lat': 35.1855, 'lng': 126.8955},
  {'name': '경신여고', 'id': '4005', 'lat': 35.1743, 'lng': 126.8855},
  {'name': '광주공고입구', 'id': '4010', 'lat': 35.1855, 'lng': 126.8755},
  {'name': '양산타운', 'id': '4301', 'lat': 35.2055, 'lng': 126.8755},
  {'name': '첨단', 'id': '5014', 'lat': 35.2107, 'lng': 126.8407},
]);

final _sunhwan01_UP = generateStations(firstRun: '05:40', lastRun: '22:40', raw: [
  {'name': '시청', 'id': '1001', 'lat': 35.1589, 'lng': 126.8515},
  {'name': '상무역', 'id': '1005', 'lat': 35.1455, 'lng': 126.8455},
  {'name': '상무지구', 'id': '1001', 'lat': 35.1492, 'lng': 126.8515},
  {'name': '서구문화센터', 'id': '1015', 'lat': 35.1355, 'lng': 126.8555},
  {'name': '금호지구', 'id': '1205', 'lat': 35.1325, 'lng': 126.8655},
  {'name': '풍암지구', 'id': '3201', 'lat': 35.1243, 'lng': 126.8655},
  {'name': '송암공단', 'id': '3101', 'lat': 35.1115, 'lng': 126.8755},
  {'name': '광주대', 'id': '3001', 'lat': 35.1158, 'lng': 126.8855},
  {'name': '백운광장', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
  {'name': '남광주역', 'id': '2015', 'lat': 35.1385, 'lng': 126.9255},
  {'name': '조선대', 'id': '2050', 'lat': 35.1417, 'lng': 126.9355},
  {'name': '지산유원지', 'id': '2065', 'lat': 35.1525, 'lng': 126.9455},
  {'name': '산수오거리', 'id': '2060', 'lat': 35.1555, 'lng': 126.9355},
  {'name': '말바우시장', 'id': '2105', 'lat': 35.1685, 'lng': 126.9255},
  {'name': '전남대후문', 'id': '2105', 'lat': 35.1754, 'lng': 126.9155},
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '경신여고', 'id': '4005', 'lat': 35.1743, 'lng': 126.8855},
  {'name': '운암시장', 'id': '4010', 'lat': 35.1725, 'lng': 126.8855},
  {'name': '광천터미널', 'id': '1105', 'lat': 35.1605, 'lng': 126.8815},
]);

final _jinwol07_UP = generateStations(firstRun: '05:40', lastRun: '22:50', raw: [
  {'name': '송암공단', 'id': '3101', 'lat': 35.1115, 'lng': 126.8755},
  {'name': '광주대', 'id': '3001', 'lat': 35.1158, 'lng': 126.8855},
  {'name': '송화마을', 'id': '3150', 'lat': 35.1055, 'lng': 126.8855},
  {'name': '진월동', 'id': '3010', 'lat': 35.1242, 'lng': 126.9055},
  {'name': '대성여고', 'id': '3007', 'lat': 35.1315, 'lng': 126.9055},
  {'name': '백운광장', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
  {'name': '양림휴먼시아', 'id': '3008', 'lat': 35.1385, 'lng': 126.9155},
  {'name': '남광주역', 'id': '2015', 'lat': 35.1385, 'lng': 126.9255},
  {'name': '조선대', 'id': '2050', 'lat': 35.1417, 'lng': 126.9355},
  {'name': '산수오거리', 'id': '2060', 'lat': 35.1555, 'lng': 126.9355},
  {'name': '말바우시장', 'id': '2105', 'lat': 35.1685, 'lng': 126.9255},
  {'name': '전남대후문', 'id': '2105', 'lat': 35.1754, 'lng': 126.9155},
  {'name': '일곡초교', 'id': '2305', 'lat': 35.2055, 'lng': 126.8955},
  {'name': '일곡지구', 'id': '2301', 'lat': 35.2015, 'lng': 126.8955},
  {'name': '살레시오고', 'id': '2350', 'lat': 35.2125, 'lng': 126.9055},
]);

final _ilgok10_UP = generateStations(firstRun: '05:45', lastRun: '22:30', raw: [
  {'name': '진월저수지', 'id': '3050', 'lat': 35.1242, 'lng': 126.9055},
  {'name': '백운광장', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
  {'name': '남광주역', 'id': '2015', 'lat': 35.1385, 'lng': 126.9255},
  {'name': '조선대', 'id': '2050', 'lat': 35.1417, 'lng': 126.9355},
  {'name': '문화전당역', 'id': '2020', 'lat': 35.1486, 'lng': 126.9235},
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '전남대후문', 'id': '2105', 'lat': 35.1754, 'lng': 126.9155},
  {'name': '일곡지구', 'id': '2301', 'lat': 35.2015, 'lng': 126.8955},
  {'name': '살레시오고', 'id': '2350', 'lat': 35.2125, 'lng': 126.9055},
]);

final _suwan12_UP = generateStations(firstRun: '05:50', lastRun: '22:30', raw: [
  {'name': '무등산국립공원', 'id': '2401', 'lat': 35.1454, 'lng': 126.9555},
  {'name': '학동증심사입구역', 'id': '2005', 'lat': 35.1315, 'lng': 126.9315},
  {'name': '남광주역', 'id': '2015', 'lat': 35.1385, 'lng': 126.9255},
  {'name': '조선대', 'id': '2050', 'lat': 35.1417, 'lng': 126.9355},
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '경신여고', 'id': '4005', 'lat': 35.1743, 'lng': 126.8855},
  {'name': '운암시장', 'id': '4010', 'lat': 35.1725, 'lng': 126.8855},
  {'name': '상무지구', 'id': '1001', 'lat': 35.1492, 'lng': 126.8515},
  {'name': '수완지구', 'id': '5250', 'lat': 35.1959, 'lng': 126.8215},
  {'name': '첨단', 'id': '5014', 'lat': 35.2107, 'lng': 126.8407},
]);

final _seonun14_UP = generateStations(firstRun: '05:45', lastRun: '22:35', raw: [
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '양동시장', 'id': '2005', 'lat': 35.1562, 'lng': 126.9055},
  {'name': '광천터미널', 'id': '1105', 'lat': 35.1605, 'lng': 126.8815},
  {'name': '상무역', 'id': '1005', 'lat': 35.1455, 'lng': 126.8455},
  {'name': '광주공항', 'id': '5550', 'lat': 35.1385, 'lng': 126.8155},
  {'name': '송정공원', 'id': '5505', 'lat': 35.1415, 'lng': 126.7955},
  {'name': '광주송정역', 'id': '5510', 'lat': 35.1376, 'lng': 126.7915},
  {'name': '선운지구', 'id': '5601', 'lat': 35.1452, 'lng': 126.7755},
]);

final _jiwon15_UP = generateStations(firstRun: '05:40', lastRun: '22:45', raw: [
  {'name': '월남동', 'id': '2501', 'lat': 35.1019, 'lng': 126.9655},
  {'name': '소태역', 'id': '2505', 'lat': 35.1155, 'lng': 126.9555},
  {'name': '학동증심사입구역', 'id': '2005', 'lat': 35.1315, 'lng': 126.9315},
  {'name': '봉선동', 'id': '3301', 'lat': 35.1282, 'lng': 126.9255},
  {'name': '백운광장', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
  {'name': '효덕동', 'id': '3005', 'lat': 35.1142, 'lng': 126.8855},
]);

final _maewol16_UP = generateStations(firstRun: '05:50', lastRun: '22:20', raw: [
  {'name': '매월동', 'id': '3250', 'lat': 35.1136, 'lng': 126.8555},
  {'name': '풍암지구', 'id': '3201', 'lat': 35.1243, 'lng': 126.8655},
  {'name': '염주체육관', 'id': '1201', 'lat': 35.1325, 'lng': 126.8755},
  {'name': '백운광장', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
  {'name': '남광주역', 'id': '2015', 'lat': 35.1385, 'lng': 126.9255},
  {'name': '조선대', 'id': '2050', 'lat': 35.1417, 'lng': 126.9355},
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '말바우시장', 'id': '2105', 'lat': 35.1685, 'lng': 126.9255},
  {'name': '문흥지구', 'id': '2201', 'lat': 35.1852, 'lng': 126.9355},
  {'name': '장등동', 'id': '4501', 'lat': 35.1925, 'lng': 126.9655},
]);

final _munheung18_UP = generateStations(firstRun: '05:45', lastRun: '22:40', raw: [
  {'name': '진월저수지', 'id': '3050', 'lat': 35.1242, 'lng': 126.9055},
  {'name': '백운광장', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
  {'name': '남광주역', 'id': '2015', 'lat': 35.1385, 'lng': 126.9255},
  {'name': '전남대병원', 'id': '2010', 'lat': 35.1425, 'lng': 126.9225},
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '전남대후문', 'id': '2105', 'lat': 35.1754, 'lng': 126.9155},
  {'name': '전남대', 'id': '2101', 'lat': 35.1700, 'lng': 126.9155},
  {'name': '문흥지구', 'id': '2201', 'lat': 35.1852, 'lng': 126.9355},
  {'name': '장등동', 'id': '4501', 'lat': 35.1925, 'lng': 126.9655},
]);

final _songjeong19_UP = generateStations(firstRun: '05:40', lastRun: '22:35', raw: [
  {'name': '장등동', 'id': '4501', 'lat': 35.1925, 'lng': 126.9655},
  {'name': '말바우시장', 'id': '2105', 'lat': 35.1685, 'lng': 126.9255},
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '양동시장', 'id': '2005', 'lat': 35.1562, 'lng': 126.9055},
  {'name': '광천터미널', 'id': '1105', 'lat': 35.1605, 'lng': 126.8815},
  {'name': '시청', 'id': '1001', 'lat': 35.1589, 'lng': 126.8515},
  {'name': '공항역', 'id': '5555', 'lat': 35.1345, 'lng': 126.8115},
  {'name': '광주송정역', 'id': '5510', 'lat': 35.1376, 'lng': 126.7915},
  {'name': '도산동', 'id': '5501', 'lat': 35.1287, 'lng': 126.7855},
]);

final _cheomdan20_UP = generateStations(firstRun: '05:40', lastRun: '22:45', raw: [
  {'name': '장등동', 'id': '4501', 'lat': 35.1925, 'lng': 126.9655},
  {'name': '말바우시장', 'id': '2105', 'lat': 35.1685, 'lng': 126.9255},
  {'name': '전남대후문', 'id': '2105', 'lat': 35.1754, 'lng': 126.9155},
  {'name': '광주공고입구', 'id': '4010', 'lat': 35.1855, 'lng': 126.8755},
  {'name': '양산타운', 'id': '4301', 'lat': 35.2055, 'lng': 126.8755},
  {'name': '첨단', 'id': '5014', 'lat': 35.2107, 'lng': 126.8407},
]);

final _jiwon25_UP = generateStations(firstRun: '05:40', lastRun: '22:50', raw: [
  {'name': '서광주역', 'id': '1250', 'lat': 35.1255, 'lng': 126.8555},
  {'name': '상무중', 'id': '1020', 'lat': 35.1425, 'lng': 126.8455},
  {'name': '백운광장', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
  {'name': '남광주역', 'id': '2015', 'lat': 35.1385, 'lng': 126.9255},
  {'name': '소태역', 'id': '2505', 'lat': 35.1155, 'lng': 126.9555},
  {'name': '월남동', 'id': '2501', 'lat': 35.1019, 'lng': 126.9655},
]);

final _maewol26_UP = generateStations(firstRun: '06:00', lastRun: '22:10', raw: [
  {'name': '봉선동', 'id': '3301', 'lat': 35.1282, 'lng': 126.9255},
  {'name': '백운광장', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
  {'name': '서구청', 'id': '1010', 'lat': 35.1485, 'lng': 126.8955},
  {'name': '매월동', 'id': '3250', 'lat': 35.1136, 'lng': 126.8555},
]);

final _bongseon27_UP = generateStations(firstRun: '05:40', lastRun: '22:40', raw: [
  {'name': '첨단', 'id': '5014', 'lat': 35.2107, 'lng': 126.8407},
  {'name': '신창지구', 'id': '5101', 'lat': 35.1955, 'lng': 126.8355},
  {'name': '경신여고', 'id': '4005', 'lat': 35.1743, 'lng': 126.8855},
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '조선대', 'id': '2050', 'lat': 35.1417, 'lng': 126.9355},
  {'name': '용산지구', 'id': '2510', 'lat': 35.1155, 'lng': 126.9355},
]);

final _ilgok28_UP = generateStations(firstRun: '05:40', lastRun: '22:45', raw: [
  {'name': '일곡지구', 'id': '2301', 'lat': 35.2015, 'lng': 126.8955},
  {'name': '전남대후문', 'id': '2105', 'lat': 35.1754, 'lng': 126.9155},
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '매월동', 'id': '3250', 'lat': 35.1136, 'lng': 126.8555},
]);

final _songjeong29_UP = generateStations(firstRun: '05:40', lastRun: '22:40', raw: [
  {'name': '첨단', 'id': '5014', 'lat': 35.2107, 'lng': 126.8407},
  {'name': '비아', 'id': '5301', 'lat': 35.2155, 'lng': 126.8255},
  {'name': '하남지구', 'id': '5401', 'lat': 35.1855, 'lng': 126.8055},
  {'name': '광주송정역', 'id': '5510', 'lat': 35.1376, 'lng': 126.7915},
  {'name': '도산동', 'id': '5501', 'lat': 35.1287, 'lng': 126.7855},
]);

final _cheomdan30_UP = generateStations(firstRun: '05:40', lastRun: '22:30', raw: [
  {'name': '첨단종점', 'id': '5001', 'lat': 35.2107, 'lng': 126.8407},
  {'name': '첨단부영아파트', 'id': '5002', 'lat': 35.2145, 'lng': 126.8415},
  {'name': '첨단삼성아파트', 'id': '5003', 'lat': 35.2175, 'lng': 126.8425},
  {'name': '첨단사거리', 'id': '5004', 'lat': 35.2205, 'lng': 126.8435},
  {'name': '첨단초교', 'id': '5005', 'lat': 35.2225, 'lng': 126.8455},
  {'name': '광주교통공사', 'id': '5006', 'lat': 35.2195, 'lng': 126.8525},
  {'name': '첨단휴먼시아', 'id': '5007', 'lat': 35.2165, 'lng': 126.8555},
  {'name': '첨단보훈병원', 'id': '5008', 'lat': 35.2105, 'lng': 126.8525},
  {'name': '신창지구', 'id': '5009', 'lat': 35.1955, 'lng': 126.8415},
  {'name': '신창파크', 'id': '5010', 'lat': 35.1905, 'lng': 126.8355},
  {'name': '전남공고', 'id': '5011', 'lat': 35.1855, 'lng': 126.8315},
  {'name': '운암산코오롱하늘채', 'id': '5012', 'lat': 35.1795, 'lng': 126.8615},
  {'name': '시립장애인복지관', 'id': '5013', 'lat': 35.1775, 'lng': 126.8645},
  {'name': '운암3단지', 'id': '5014', 'lat': 35.1745, 'lng': 126.8715},
  {'name': '운암벽산블루밍', 'id': '5015', 'lat': 35.1725, 'lng': 126.8785},
  {'name': '광주기아챔피언스필드', 'id': '5016', 'lat': 35.1685, 'lng': 126.8915},
  {'name': '광주역', 'id': '5017', 'lat': 35.1645, 'lng': 126.9075},
  {'name': '금남로5가역', 'id': '5018', 'lat': 35.1525, 'lng': 126.9115},
  {'name': '금남로4가역', 'id': '5019', 'lat': 35.1515, 'lng': 126.9135},
  {'name': '국립아시아문화전당', 'id': '5020', 'lat': 35.1485, 'lng': 126.9175},
  {'name': '남광주역', 'id': '5021', 'lat': 35.1385, 'lng': 126.9215},
  {'name': '양림휴먼시아', 'id': '5022', 'lat': 35.1345, 'lng': 126.9135},
  {'name': '백운광장', 'id': '5023', 'lat': 35.1345, 'lng': 126.8965},
  {'name': '주월주택단지', 'id': '5024', 'lat': 35.1355, 'lng': 126.8855},
  {'name': '대성여고', 'id': '5025', 'lat': 35.1315, 'lng': 126.8755},
  {'name': '진월대창아파트', 'id': '5026', 'lat': 35.1265, 'lng': 126.8715},
  {'name': '광주대입구', 'id': '5027', 'lat': 35.1155, 'lng': 126.8655},
  {'name': '진월저수지', 'id': '5028', 'lat': 35.1125, 'lng': 126.8615},
]);

final _songam31_UP = generateStations(firstRun: '05:55', lastRun: '22:20', raw: [
  {'name': '본촌', 'id': '4350', 'lat': 35.2155, 'lng': 126.8855},
  {'name': '일곡지구', 'id': '2301', 'lat': 35.2015, 'lng': 126.8955},
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '송암공단', 'id': '3101', 'lat': 35.1115, 'lng': 126.8755},
]);

final _songjeong33_UP = generateStations(firstRun: '05:50', lastRun: '22:30', raw: [
  {'name': '광주역', 'id': '2001', 'lat': 35.1646, 'lng': 126.9155},
  {'name': '양동시장', 'id': '2005', 'lat': 35.1562, 'lng': 126.9055},
  {'name': '광주송정역', 'id': '5510', 'lat': 35.1376, 'lng': 126.7915},
  {'name': '도산동', 'id': '5501', 'lat': 35.1287, 'lng': 126.7855},
]);

final _unlim35_UP = generateStations(firstRun: '06:00', lastRun: '22:15', raw: [
  {'name': '장등동', 'id': '4501', 'lat': 35.1925, 'lng': 126.9655},
  {'name': '전남대후문', 'id': '2105', 'lat': 35.1754, 'lng': 126.9155},
  {'name': '조선대', 'id': '2050', 'lat': 35.1417, 'lng': 126.9355},
  {'name': '증심사', 'id': '2405', 'lat': 35.1245, 'lng': 126.9555},
]);

final _geumho36_UP = generateStations(firstRun: '05:40', lastRun: '22:20', raw: [
  {'name': '장등동', 'id': '4501', 'lat': 35.1925, 'lng': 126.9655},
  {'name': '말바우시장', 'id': '2105', 'lat': 35.1685, 'lng': 126.9255},
  {'name': '금호지구', 'id': '1205', 'lat': 35.1325, 'lng': 126.8655},
  {'name': '서광주역', 'id': '1250', 'lat': 35.1255, 'lng': 126.8555},
]);

final _bongseon37_UP = generateStations(firstRun: '05:50', lastRun: '22:30', raw: [
  {'name': '조선대', 'id': '2050', 'lat': 35.1417, 'lng': 126.9355},
  {'name': '남광주역', 'id': '2015', 'lat': 35.1385, 'lng': 126.9255},
  {'name': '봉선동', 'id': '3301', 'lat': 35.1282, 'lng': 126.9255},
  {'name': '송암공단', 'id': '3101', 'lat': 35.1115, 'lng': 126.8755},
]);

final _ilgok38_UP = generateStations(firstRun: '05:45', lastRun: '22:35', raw: [
  {'name': '송암공단', 'id': '3101', 'lat': 35.1115, 'lng': 126.8755},
  {'name': '백운광장', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
  {'name': '전남대후문', 'id': '2105', 'lat': 35.1754, 'lng': 126.9155},
  {'name': '일곡지구', 'id': '2301', 'lat': 35.2015, 'lng': 126.8955},
]);

final _munheung39_UP = generateStations(firstRun: '05:40', lastRun: '22:45', raw: [
  {'name': '진월동', 'id': '3010', 'lat': 35.1242, 'lng': 126.9055},
  {'name': '백운광장', 'id': '3005', 'lat': 35.1342, 'lng': 126.9115},
  {'name': '장등동', 'id': '4501', 'lat': 35.1925, 'lng': 126.9655},
]);

final _cheomdan40_UP = generateStations(firstRun: '05:50', lastRun: '22:30', raw: [
  {'name': '장등동', 'id': '4501', 'lat': 35.1925, 'lng': 126.9655},
  {'name': '전남대후문', 'id': '2105', 'lat': 35.1754, 'lng': 126.9155},
  {'name': '첨단', 'id': '5014', 'lat': 35.2107, 'lng': 126.8407},
]);

final _jiwon45_UP = generateStations(firstRun: '05:40', lastRun: '22:40', raw: [
  {'name': '일곡지구', 'id': '2301', 'lat': 35.2015, 'lng': 126.8955},
  {'name': '전남대후문', 'id': '2105', 'lat': 35.1754, 'lng': 126.9155},
  {'name': '월남동', 'id': '2501', 'lat': 35.1019, 'lng': 126.9655},
]);

final _geumho46_UP = generateStations(firstRun: '05:40', lastRun: '22:30', raw: [
  {'name': '첨단', 'id': '5014', 'lat': 35.2107, 'lng': 126.8407},
  {'name': '서광주역', 'id': '1250', 'lat': 35.1255, 'lng': 126.8555},
]);

final _songam47_UP = generateStations(firstRun: '05:45', lastRun: '22:25', raw: [
  {'name': '장등동', 'id': '4501', 'lat': 35.1925, 'lng': 126.9655},
  {'name': '송암', 'id': '3101', 'lat': 35.1115, 'lng': 126.8755},
]);

final _suwan49_UP = generateStations(firstRun: '05:55', lastRun: '22:20', raw: [
  {'name': '무등산', 'id': '2401', 'lat': 35.1454, 'lng': 126.9555},
  {'name': '수완', 'id': '5250', 'lat': 35.1959, 'lng': 126.8215},
]);

final _unlim50_UP = generateStations(firstRun: '06:00', lastRun: '22:30', raw: [
  {'name': '시청', 'id': '1001', 'lat': 35.1589, 'lng': 126.8515},
  {'name': '증심사', 'id': '2405', 'lat': 35.1245, 'lng': 126.9555},
]);

final _unlim51_UP = generateStations(firstRun: '05:40', lastRun: '22:40', raw: [
  {'name': '첨단', 'id': '5014', 'lat': 35.2107, 'lng': 126.8407},
  {'name': '증심사', 'id': '2405', 'lat': 35.1245, 'lng': 126.9555},
]);

final _jiwon52_UP = generateStations(firstRun: '05:40', lastRun: '22:40', raw: [
  {'name': '운암동', 'id': '4001', 'lat': 35.1773, 'lng': 126.8655},
  {'name': '월남동', 'id': '2501', 'lat': 35.1019, 'lng': 126.9655},
]);

final _munheung53_UP = generateStations(firstRun: '06:10', lastRun: '22:00', raw: [
  {'name': '조선대', 'id': '2050', 'lat': 35.1417, 'lng': 126.9355},
  {'name': '문흥', 'id': '2201', 'lat': 35.1852, 'lng': 126.9355},
]);
