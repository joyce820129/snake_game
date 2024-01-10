module final_project(
	output reg[0:7] LedR,LedG,LedB,  //三個8位元的LED顏色輸出，分別表示紅色、綠色和藍色
	output reg[2:0] comm,
	output reg enable,
	output reg [7:0] point,
	output reg [6:0] seg,
	output reg [1:0] COM,
	input SYS_CLK,RST,PAUSE,UP,DOWN,LEFT,RIGHT  
        //輸入信號包括系統時鐘、重置、暫停以及上、下、左、右四個方向控制
);
	
	reg [1:0]state;               //2位元的狀態機，表示遊戲狀態（01：遊戲中，10：結束）
	
	reg game_clk;                 //遊戲時鐘
	reg led_clk;                  //LED顯示時鐘
	
	reg [7:0] map [7:0];          //8x8的LED地圖，用於存儲蛇的位置信息
	
	reg [2:0] X,Y;                //蛇頭的X和Y坐標
	reg [2:0] body_mem_x[63:0];   //蛇身體的X坐標記憶陣列
	reg [2:0] body_mem_y[63:0];   //蛇身體的Y坐標記憶陣列
	reg [5:0] length;             //蛇的長度，包括頭
	
	reg [2:0] item_x,item_y;      //物品的X和Y坐標

	reg STOP;
	reg round;                    //第幾關
	reg pass;                     //標誌是否通過物品
	reg [7:0] pass_pic [7:0];     //通過物品時的顯示效果
	
	reg [6:0] i;                  //迴圈遞增變數
	reg [5:0] j;                  //迴圈遞增變數
	
	reg [24:0] led_counter;       //LED計數器
	reg [24:0] move_counter;      //遊戲計數器
	reg [1:0] move_dir;           //蛇的移動方向
	
	
	
	integer led_count_to =50000;  //LED時鐘計數器的上限值
	integer count_to = 4500000;   //遊戲時鐘計數器的上限值 (game_clk 0.5hz)
	
	//失敗哭臉
	parameter logic [7:0] L_Char [7:0] =
		'{8'b11111111,
		  8'b11011011,
		  8'b11011011,
		  8'b11011011,
		  8'b11111111,
		  8'b11000011,
		  8'b10111101,
		  8'b11111111};
		  		  
	//成功笑臉
	parameter logic [7:0] W_Char [7:0] =
		'{8'b11111111,
		  8'b11011011,
		  8'b11011011,
		  8'b11011011,
		  8'b11111111,
		  8'b10111101,
		  8'b11000011,
		  8'b11111111};
	
   reg [2:0] cnt;
				  
	
	//倒數計時
	reg fail;
	reg [3:0] B_count,A_count;
	reg [2:0] cc;
	reg [6:0] seg1, seg2, seg3;
	divfreq 	(SYS_CLK ,clk_div);
	divfreq2	(SYS_CLK ,clk_div2);
	BCD2Seg S0(A_count, A0,B0,C0,D0,E0,F0,G0);
	BCD2Seg S1(B_count, A1,B1,C1,D1,E1,F1,G1);
	//BCD2Seg S2(C_count, A2,B2,C2,D2,E2,F2,G2);
	
	
//初始化
	initial begin
		//initial Led
		LedR = 8'b11111111;
		LedG = 8'b11111111;
		LedB = 8'b11111111;
		enable = 1'b1;
		comm = 3'b000;
		
		STOP = 1'b0;
		round = 1'd1;
		pass = 1'b0;
		
		pass_pic[3'b000]=8'b00000000;
		pass_pic[3'b001]=8'b11110110;
		pass_pic[3'b010]=8'b11110110;
		pass_pic[3'b011]=8'b11110110;
		pass_pic[3'b100]=8'b11110110;
		pass_pic[3'b101]=8'b11110110;
		pass_pic[3'b110]=8'b11110110;
		pass_pic[3'b111]=8'b11110000;
		
		//initial [2,2] to the start pos
		map[3'b010][~3'b010]=1'b1; //在地圖的特定位置標記為1，表示蛇的頭部  
		map[3'b001][~3'b010]=1'b1; //在地圖的另一個位置標記為1，表示蛇的身體
		map[3'b000][~3'b010]=1'b1; //在地圖的另一個位置標記為1，表示蛇的身體

		
		item_x = 3'b110;           //初始化物品的X坐標
		item_y = 3'b110;           //初始化物品的Y坐標
		
		point =8'b00000000;        //初始化分數為0
		
		X = 3'b010;                //初始化蛇頭的X坐標
		Y = 3'b010;                //初始化蛇頭的Y坐標
		//head
		body_mem_x[0] =3'b010;     //初始化蛇頭的X坐標
		body_mem_y[0] =3'b010;     //初始化蛇頭的Y坐標
		//body1
		body_mem_x[1] =3'b010;     //初始化蛇的第一節身體的X坐標
		body_mem_y[1] =3'b001;     //初始化蛇的第一節身體的Y坐標
		//body2
		body_mem_x[2] =3'b010;     //初始化蛇的第二節身體的X坐標
		body_mem_y[2] =3'b000;     //初始化蛇的第二節身體的Y坐標
		length = 3;                //初始化蛇的長度為3
		state =2'b01;              //初始化遊戲的狀態為01，表示遊戲進行中
		move_dir = 2'b00;          //初始化蛇的移動方向為00，表示遊戲開始時的方向
		
		fail = 0;
		COM = 3'b000;
		A_count=0;      //個位數
		B_count=9;      //十位數
		//C_count=3;
		
	end
	
	
//將七段顯示器的輸出seg1、seg2、seg3連接到相應的數位顯示元件
		always@(posedge clk_div2)
			  begin
					seg1[0] = A0;
					seg1[1] = B0;
					seg1[2] = C0;
					seg1[3] = D0;
					seg1[4] = E0;
					seg1[5] = F0;
					seg1[6] = G0;
					
					seg2[0] = A1;
					seg2[1] = B1;
					seg2[2] = C1;
					seg2[3] = D1;
					seg2[4] = E1;
					seg2[5] = F1;
					seg2[6] = G1;
					
					/*
					seg3[0] = A2;
					seg3[1] = B2;
					seg3[2] = C2;
					seg3[3] = D2;
					seg3[4] = E2;
					seg3[5] = F2;
					seg3[6] = G2;
					*/
					
					if(cc == 0)
						begin
							seg <= seg1;
							COM[0] <= 1'b0;
							COM[1] <= 1'b1;
							//COM[2] <= 1'b1;
							cc <= 1;
						end
					else if(cc == 1)
						begin
							seg <= seg2;
							COM[0] <= 1'b1;
							COM[1] <= 1'b0;
							//COM[2] <= 1'b1;
							cc <= 0;
						end
					/*
					else if(cc == 2)
						begin
							seg <= seg3;
							COM[1] <= 1'b1;
							COM[0] <= 1'b1;
							COM[2] <= 1'b0;
							cc <= 0;
						end
					*/
			  end

			  
			  	  
			 
//用來處理倒數計時器的邏輯
		always@(posedge clk_div)
			begin
					if(A_count == 0 && B_count == 0)
						   fail = 1;
							
							
					if(!fail && !PAUSE && !STOP)
						begin
								if(A_count == 0)                       //如果A_count為0
									 begin
										 A_count <= 9;                   //將A_count重新設置為9
										 B_count <= B_count - 1;         //將B_count減1
									 end
								else                                   //如果A_count不為0
									 A_count <= A_count - 1;            //將A_count減1
								/*
								if(B_count == 0 && A_count == 0)       //如果B_count和A_count均為0
									 begin
										 B_count <= 5;                   //將B_count重新設置為5
											if(C_count != 0)              //如果C_count不為0
												C_count <= C_count - 1;    //將C_count減1
									 end
								*/
						end
			 end	
			
	
	
//系統時鐘轉換為遊戲時鐘和LED時鐘
	always @(posedge SYS_CLK) begin
		if(PAUSE == 1'b1 || STOP == 1'b1); // 若遊戲暫停，不執行計數
           
			  
	   //如果遊戲沒有暫停且計數器（move_counter）小於計數上限（count_to）
		else if(move_counter < count_to) 
		    begin
			move_counter <= move_counter+1;       //遞增計數器
		    end
            
		else                                     //如果計數器達到上限
		    
		    begin
		   	game_clk <= ~game_clk;             //翻轉遊戲時鐘的狀態
		   	move_counter <= 25'b0;             //將計數器歸零
		    end
		
            
		//LED clk
		if(led_counter < led_count_to)           //如果LED計數器（led_counter）小於LED時鐘計數器的上限（led_count_to）
			led_counter <= led_counter + 1;       //遞增LED計數器

		else	
		    //如果LED計數器達到上限
		    begin
			   led_clk <= ~led_clk;               //翻轉LED時鐘的狀態
			   led_counter <= 25'b0;              //將計數器歸零
		    end
	end	
	

//實現LED顯示的掃描
	always @(posedge led_clk) 
		begin
		   if(state==2'b00 || state==2'b10)
			   begin			
					comm = {1'b1,cnt}; 
				end	
				
			else if(comm == 3'b111) comm <= 3'b000;
			else 	
				begin			
					comm <= comm + 1'b1;
				end					
		end	
           
//根據地圖資訊將LED顯示不同的顏色
	always@(comm) begin
           //if(state==2'b10)                        //如果遊戲狀態=10為遊戲結束
               /*
					begin
                   LedG = ~map[comm];              //將LED的綠色通道（LedG）設定為地圖（map）在當前通信信號位置的反相值
               end*/

			  if(state==2'b00)                   //如果遊戲狀態=00為失敗
			      begin
                   LedR = ~map[comm];              //將LED的綠色通道（LedG）設定為地圖（map）在當前通信信號位置的反相值
               end
			  
           else                                    //如果遊戲狀態=01是持續進行
               LedB = ~map[comm];
					
					
			  //如果通信信號等於物品的X坐標（item_x），則將紅色通道（LedR）的相應位置設為低電平（0）
           if(comm == item_x ) LedR[item_y] = 1'b0;
           else LedR =8'b11111111;
		
	end
	

	
	
//更新蛇的移動方向
  always @( UP or DOWN or LEFT or RIGHT) begin // 這四個方向不能都用"posedge"

		if(UP == 1'b1 && DOWN !=1'b1 && LEFT != 1'b1 && RIGHT != 1'b1 && move_dir != 2'b01)     move_dir = 2'b00;  
		else if(DOWN == 1'b1  && UP !=1'b1 && LEFT != 1'b1 && RIGHT != 1'b1 && move_dir != 2'b00)  move_dir = 2'b01; 
		else if(LEFT == 1'b1 && UP !=1'b1 && DOWN != 1'b1 && RIGHT != 1'b1 && move_dir != 2'b11)   move_dir = 2'b10; 
		else if(RIGHT == 1'b1 && UP != 1'b1 && DOWN !=1'b1 && LEFT != 1'b1 &&  move_dir != 2'b10 ) move_dir = 2'b11; 
		else ;
  end
  
 
//蛇的移動、地圖更新和處理得分
	always@(posedge game_clk) begin
        
			if(move_dir == 2'b00) Y <= Y+1;
			else if(move_dir == 2'b01) Y <= Y-1;
			else if(move_dir == 2'b10) X <= X-1;
			else if(move_dir == 2'b11) X <= X+1;
               
			//將地圖上的蛇頭位置（X，Y）設置為1
			map[X][~Y] <= 1'b1;

			
			if(fail == 1)  state=2'b00;
			
			//如果得分小於1，則將遊戲狀態設置為01，表示遊戲進行中
			else if(point < 8'b00000001)	state=2'b01;
             
			//如果蛇頭的位置與物品的位置相同
			if(X==item_x && Y==item_y) 
			    begin
				    //如果得分大於8'b11111110，則將遊戲狀態設置為10，表示遊戲結束
				    if(point>8'b11111110) 
					 begin
					   state=2'b10;
				      STOP=1'b1;
					 end
					 
					 point = point*2 + 1'b1;
				
				    //改變物品的位置
				    if(move_dir==2'b00 || move_dir == 2'b01)
				        begin	
				    	    item_x = X +3'b011 +game_clk*2;
				    	    item_y = Y -3'b011 +game_clk;
				        end 
				    else 
				        begin
				    	    item_x = X -3'b011 -game_clk;
				    	    item_y = Y +3'b011 -game_clk*2;
				        end
			    end
			
			//將地圖上上一個蛇尾位置設置為0
			map[body_mem_x[length-1]][~body_mem_y[length-1]] = 1'b0;			

			//從蛇尾到蛇頭，對每個身體節點執行以下操作
			for(i = 1; i < length;i = i+1) 
			    begin
				    //將身體節點的X坐標更新為前一個身體節點的X坐標
				    body_mem_x[length-i] <= body_mem_x[length-i-1];

				    //將身體節點的Y坐標更新為前一個身體節點的Y坐標
				    body_mem_y[length-i] <= body_mem_y[length-i-1];
			    end
            
			//將蛇頭的X坐標更新到身體的第一個節點
			body_mem_x[0] = X;

			//將蛇頭的Y坐標更新到身體的第一個節點
			body_mem_y[0] = Y;
			
	end

endmodule


//秒數轉7段顯示器
module BCD2Seg(input [3:0] D_count, output reg a,b,c,d,e,f,g);
  always @(D_count)
    case(D_count)
	      4'b0000:{a,b,c,d,e,f,g}=7'b1000000;  //7'b0000001
			4'b0001:{a,b,c,d,e,f,g}=7'b1111001;  //7'b1001111
			4'b0010:{a,b,c,d,e,f,g}=7'b0100100;  //7'b0010010
			4'b0011:{a,b,c,d,e,f,g}=7'b0110000;  //7'b0000110
			4'b0100:{a,b,c,d,e,f,g}=7'b0011001;  //7'b1001100
			4'b0101:{a,b,c,d,e,f,g}=7'b0010010;  //7'b0100100
			4'b0110:{a,b,c,d,e,f,g}=7'b0000010;  //7'b0100000
			4'b0111:{a,b,c,d,e,f,g}=7'b1111000;  //7'b0001111
			4'b1000:{a,b,c,d,e,f,g}=7'b0000000;  //7'b0000000
			4'b1001:{a,b,c,d,e,f,g}=7'b0010000;  //7'b0000100
			default:{a,b,c,d,e,f,g}=7'b1111111;  //7'b1111111
    endcase
endmodule



module divfreq(input SYS_CLK, output reg clk_div);
	reg [24:0] Count;
	always @(posedge SYS_CLK)
		begin
			if(Count > 25000000)
				begin
					Count <= 25'b0;
					clk_div <= ~clk_div;
				end
			else Count <= Count + 1'b1;
		end
endmodule 

module divfreq2(input SYS_CLK, output reg clk_div2);
	reg [24:0] Count2;
	always @(posedge SYS_CLK)
		begin
			if(Count2 > 10000)
				begin
					Count2 <= 25'b0;
					clk_div2 <= ~clk_div2;
				end
			else Count2 <= Count2 + 1'b1;
		end
endmodule
