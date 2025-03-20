import requests, numpy, json, pandas, time, random

from rich import print
from scipy.spatial.distance import cosine
from flask import Flask, request, jsonify

OllamaAPI = "http://localhost:11434"
Model = "all-minilm"

def _embedding_(text: str):
    """
    將文字 => 向量

    參數:
        text: 檔案名稱
    """
    json = { 'model': Model, 'input': [text] }

    response = requests.post(f'{OllamaAPI}/api/embed', json=json)
    return response.json()['embeddings'][0]

def _vectorList_(dataFrame: pandas.DataFrame):
    """
    將問題 => 向量

    參數:
        dataFrame: 已讀出的CSV檔資訊
    """
    list = []

    for row in dataFrame.itertuples():
        key = row.gpt_q
        value = _embedding_(key)
        list.append({'question': key, 'vector': value})

    return list

def _writeVectorJSON_(list: list, filename: str, encoding: str):
    """
    將問題List => 存成.json

    參數:
        filename: 檔案名稱
        encoding: 文字編碼
    """
    with open(filename, 'w', encoding=encoding) as file:
        json.dump(list, file, ensure_ascii=False)

def _readVectorJSON_(filename: str, encoding: str):
    """
    將向量json => Array

    參數:
        filename: 檔案名稱
        encoding: 文字編碼
    """
    with open(filename, 'r', encoding=encoding) as file:
        list = json.load(file)

    return numpy.asarray(list)

def _similarIndexList_(input: str, vectorArray: list, threshold: float):
    """
    將輸入文字比較相似值

    參數:
        input: 輸入文字
        vectorArray: 轉成向量的比較列表
        threshold: 相似值的基準值 (0.0 ~ 1.0)
    """
    inputVec = _embedding_(input)
    indexArray = []

    for index in range(len(vectorArray)):

        map = {}
        vector = vectorArray[index]["vector"]
        similarity = 1 - cosine(inputVec, vector)

        if (similarity > threshold):
            map["similarity"] = similarity
            map["index"] = index
            indexArray.append(map)

    return indexArray

def _similarList_(dataFrame: pandas.DataFrame, indexArray: list):
    """
    從已讀出的CSV檔資訊 => 取出特定index的資訊

    參數:
        dataFrame: 已讀出的CSV檔資訊
        indexArray: 特定index列表
    """

    indices = []
    for index in range(len(indexArray)):
        indices.append(indexArray[index]["index"])
    
    return dataFrame.iloc[indices]

def _combineQuestions_(rows: pandas.DataFrame, indexArray: list):
    """
    從已讀出的CSV檔資訊 => 方便前台處理的格式

    參數:
        rows: 已讀出的特定列的CSV檔資訊
        indexArray: 特定index列表
    """
    questions = []

    for index in range(len(rows)):
        row = rows.iloc[index]

        similarity = 1.0        
        gpt_q = f'根據 {row.files} 數據，分析{row.gpt_q}'
        user_q = row.user_q
        
        if (indexArray != None): similarity = float(indexArray[index]["similarity"])
        questions.append({ "gpt_q":gpt_q, "user_q": user_q, "similarity": similarity })

    return questions

def _randomMenu_(dataFrame: pandas.DataFrame, count: int):
    """
    從已讀出的CSV檔資訊 => 隨機取得3筆選單

    參數:
        count: 隨機幾筆選單
    """
    randomState = int(time.time())
    return dataFrame.sample(n=count, replace=False, random_state = randomState)

def _combineRandomMenu_(dataFrame: pandas.DataFrame, count: int):
    """
    從已讀出的CSV檔資訊 => 方便前台處理的格式隨機選單

    參數:
        rows: 已讀出的特定列的CSV檔資訊
        indexArray: 特定index列表
    """
    menu = _randomMenu_(dataFrame, count)
    return _combineQuestions_(menu, None)

def questions(input: str, isRefresh: bool, count: int, threshold: float, encoding = 'utf-8', tableName = "question.csv", filename = "vector.json"):
    """
    取得選單問題 => {"result:":{"menu":[<CSV中的選單問題>],"question":[<比較後產生的近似問題>]},"error":<錯誤訊息>}
    
    參數:
        input: 輸入文字
        count: 隨機幾筆選單
        threshold: 相似值的基準值 (0.0 ~ 1.0)
        encoding: 字元編碼
        tableName: 問題列表的CSV檔名
        filename: 記錄問題向量的JSON檔名
    """

    error = {}
    randomMenu = []
    randomQuestions = []
    dataFrame = pandas.read_csv(tableName)

    if len(input) == 0:
        randomMenu = _combineRandomMenu_(dataFrame, count)
        return { "menu": randomMenu, "question": {}, "error": error }

    if isRefresh:
        vectors = _vectorList_(dataFrame)
        _writeVectorJSON_(vectors, filename, encoding)
    
    vectorArray = _readVectorJSON_(filename, encoding)
    indexArray = _similarIndexList_(input, vectorArray, threshold)
    rows = _similarList_(dataFrame, indexArray)
    questions = _combineQuestions_(rows, indexArray)

    random.shuffle(questions)
    randomQuestions = questions[:count]

    if not questions:
        randomMenu = _combineRandomMenu_(dataFrame, count)
        error["message"] = "您所輸入的問題我不太了解，請您再輸入一次…"
    
    return { "result:": {"menu": randomMenu, "question": randomQuestions}, "error": error }

app = Flask(__name__)

# 隨機選單 => 參數：{"input":"<問題>","isRefresh":false,"count":3,"threshold":0.7}
@app.route('/menu', methods=['POST'])
def randomMenu():
    
    input = ""
    isRefresh = False
    count = 3
    threshold = 0.8
    
    if request.is_json:

        json = request.json
        input = json.get('input')
        isRefresh = json.get("isRefresh")
        count = json.get("count")
        threshold = json.get("threshold")

        if input is None: input = ""
        if isRefresh is None: isRefresh = False
        if count is None: count = 3
        if threshold is None: threshold = 0.8

    result = questions(input=input, isRefresh=isRefresh, count=count, threshold=threshold)
    return jsonify(result)

if __name__ == '__main__':
    app.run(debug=True)
