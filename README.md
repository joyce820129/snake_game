# 貪食蛇
* 整體介面，使用4-bits Switch來控制方向，暫停的選項是8 DIPSW的紅色第1個開關
* 按下任意方向鍵後，遊戲開始，倒數計時90秒
* 玩到8分後，頭會停留在原地
![243935](https://github.com/joyce820129/snake_game/assets/104434994/dd9ca32a-df75-4e03-963d-6e43f0f45412)


- - -

## 前言:
組別:四<br>
組員:
```
111321018 黃靖喬
111321026 劉也慈
111321058 葉容
```

- - - 

## 目錄:
* 1. [/功能]
* 2. [/功能影片]
* 3. [/Pin腳位]
* 4. [/參考]

 - - -
## 功能:
* 1. 在8x8的LED全彩點矩陣上，隨機生成蛇的食物(會避開蛇的身體位置)
* 2. 用七段顯示器實現90秒倒數計時
* 3. 若時間倒數至0，且未吃滿8分，則強制結束遊戲，8x8全彩點矩陣會全部熄滅
* 4. 新增暫停功能，當PAUSE=1時，時間與8x8全彩點矩陣會暫停動作
* 5. 時間內成功吃掉8分，倒計時暫停，畫面停留於蛇頭最後位置
* 6. 可更改蛇移動的速度

 - - -

## 功能影片:
https://youtu.be/dcyxiAzyniY
- - -

## Pin腳位:
`使用EP3C10E144C8`
<table>
  <tr>
    <th>操控功能</th>
    <th>控制元件</th>
    <th>備註</th>
  </tr>
  <tr>
    <td>上</td>
    <td>S1</td>
    <td>在4 BITS SW</td>
  </tr>
  <tr>
    <td>下</td>
    <td>S2</td>
    <td>在4 BITS SW</td>
  </tr>
  <tr>
    <td>左</td>
    <td>S3</td>
    <td>在4 BITS SW</td>
  </tr>
  <tr>
    <td>右</td>
    <td>S4</td>
    <td>在4 BITS SW</td>
  </tr>
  <tr>
    <td>暫停</td>
    <td>紅色第1號開關</td>
    <td>在8 DIPSW</td>
  </tr>
</table>

`Cyclone iii`
- - -

## 參考:
* https://github.com/vale5230/Snake-Game-in-FPGA
- - -


