//2025-02-21

// common strings/field names
const kpmAction = 'action';
const kpmAdd = 'add';
const kpmAndroid = 'android';
const kpmArgs = 'args';
const kpmCenter = 'center';
const kpmColor = 'Color';
const kpmContext = 'context';
const kpmCredentials = 'credentials';
const kpmData = 'data';
const kpmDATE = 'DATE';
const kpmDelete = 'delete';
const kpmDir = 'dir';
const kpmDocId = 'docId';
const kpmDOWN = 'DOWN';
const kpmDropDown = 'dropdown';
const kpmDropdownCallback = 'DropdownCallback';
const kpmEdit = 'edit';
const kpmEnd = 'end';
const kpmEntry = 'entry';
const kpmExpress = 'express';
const kpmFailure = 'failure';
const kpmFalse = 'false';
const kpmFatal = 'fatal';
const kpmFileName = 'fileName';
const kpmFullPath = 'full path';
const kpmHeight = 'height';
const kpmHide = 'hide';
const kpmHoldingCheckFunction = 'holding check';
const kpmImage = 'image';
const kpmIndex = 'index';
const kpmInitialized = 'initialized';
const kpmInsert = 'insert';
const kpmLength ='length';
const kpmKey = 'key';
const kpmMax = 'max';
const kpmMessage = 'message';
const kpmMin = 'min';
const kpmModel = 'model';
const kpmName = 'name';
const kpmPARAMETERS = 'PARAMETERS';
const kpmParsePath = 'ParsePath';
const kpmPath = 'path';
const kpmPending = 'pending';
const kpmPlay = 'play';
const kpmErrorPage = '/PMErrorPage';
const kpmReplace = 'replace';
const kpmRoute = 'route';
const kpmRouteSaveFunction = 'save route';
const kpmSave = 'save';
const kpmSchema = 'schema';
const kpmShow = 'show';
const kpmSize = 'size';
const kpmSort = 'sort';
const kpmSpinner = 'spinner';
const kpmStart = 'start';
const kpmStop = 'stop';
const kpmSuccess = 'success';
const kpmTextCallback = 'TextCallback';
const kpmTextCheck = 'TextCheck';
const kpmTIME = 'TIME';
const kpmTimeStamp = 'timeStamp';
const kpmTRANSFORMS = 'TRANSFORMS';
const kpmTransforms = 'transforms';
const kpmTrigger = 'trigger';
const kpmTrue = 'true';
const kpmType = 'type';
const kpmUserName = 'userName';
const kpmUserPassword = 'userPassword';
const kpmValue = 'value';
const kpmWidth = 'width';
const kpmWindows = 'windows';
const kpmXFormToS = 'XFormToS';

const kpmWindowsSeparator = r'\';
const kpmDefaultSeparator = '/';

class PMCV {
  // ASCII Code Values
  static const A = 65;
  static const Z = 90;
  static const a = 97;
  static const z = 122;
  static const Zero = 48;
  static const Nine = 57;
  static const Ampersand = 38;
  static const AtSymbol = 64;
  static const BackSlash = 92; // \
  static const BackTick = 96;
  static const Colon = 58;
  static const Comma = 44;
  static const CR = 13;
  static const Dash = 45; // -
  static const DollarSign = 36;
  static const DoubleQ = 34; // "
  static const EqualSign = 61;
  static const Exclamation = 33;
  static const ForwardSlash = 47;
  static const GreaterThan = 62;
  static const Hash = 35;
  static const Hat = 94; // ^
  static const LeftBracket = 40; //(
  static const LeftCurlyBracket = 123; //{
  static const LeftSquareBracket = 91; //[
  static const LessThan = 60; // ^
  static const LF = 10;
  static const Percent = 37;
  static const Period = 46;
  static const Plus = 43;
  static const QuestionMark = 33;
  static const RightBracket = 41; // )
  static const RightCurlyBracket = 125; // }
  static const RightSquareBracket = 93; // ]
  static const SemiColon = 59;
  static const Separator = 124; // |
  static const SingleQ = 39; // '
  static const Space = 32;
  static const Tab = 9;
  static const Tilde = 126; // ~
  static const Underscore = 95; // _
}

List kpmUrlEncodings = [
  [PMCV.LF, '%0A'],
  [PMCV.CR, '%0D'],
  [PMCV.Tab, '%09'],
  [PMCV.DollarSign, '%24'],
  [PMCV.Ampersand, '%26'],
  [PMCV.Plus, '%2B'],
  [PMCV.Comma, '%2C'],
  [PMCV.ForwardSlash, '%2F'],
  [PMCV.Colon, '%3A'],
  [PMCV.SemiColon, '%3B'],
  [PMCV.EqualSign, '%3D'],
  [PMCV.QuestionMark, '%3F'],
  [PMCV.AtSymbol, '%40'],
  [PMCV.Space, '%20'],
  [PMCV.DoubleQ, '%22'],
  [PMCV.LessThan, '%3C'],
  [PMCV.GreaterThan, '%3E'],
  [PMCV.Hash, '%23'],
  [PMCV.Percent, '%25'],
];





