#include "display.h"
#include "image.h"
#include "myhead.h"
#include "string.h"
extern u32 key;
u8 pre[4][5];
int paint(void)
{
    switch(page)
    {
        case 0:
            if(checkBack == 0)//如果背景还没画，那就画背景图
            {
                BitBlt(0,0,640,480,page_song,0,0,640);
                TransparentBlt(0,0,100,100,easy_on,108,259,100,100,trans);
                TransparentBlt(0,0,100,100,mid_off,270,259,100,100,trans);
                TransparentBlt(0,0,100,100,hard_off,428,259,100,100,trans);
                checkBack = 1;
            }

            //显示分数
            //LCD_ShowNum(273,283,point,49,0);

            switch(lastOrder)
            {//覆盖上一次的滑块
                case 0:
                    TransparentBlt(0,0,100,100,easy_off,108,259,100,100,trans);
                break;

                case 1:
                    TransparentBlt(0,0,100,100,mid_off,270,259,100,100,trans);
                break;

                case 2:
                    TransparentBlt(0,0,100,100,hard_off,428,259,100,100,trans);
                break;

                default:
                    lastOrder = 0;
                break;
            }

            switch(songOrder)
            {//绘图当前的滑块
                case 0:
                    TransparentBlt(0,0,100,100,easy_on,108,259,100,100,trans);
                break;

                case 1:
                    TransparentBlt(0,0,100,100,mid_on,270,259,100,100,trans);
                break;

                case 2:
                    TransparentBlt(0,0,100,100,hard_on,428,259,100,100,trans);
                break;

                default:
                    songOrder = 0;
                break;
            }

        break;

        case 1:
            if(checkBack == 0)//如果背景还没画，那就画背景图
            {
                BitBlt(0,0,640,480,page_game,0,0,640);
                checkBack = 1;
            }

            for(i=0;i<TMAX-1;i++)
            {   //先覆盖上一次的滑块
            	if(pre[0][i]){BitBlt(prePos_0[i][0],prePos_0[i][1],prePos_0[i][2],prePos_0[i][3],page_game,prePos_0[i][0],prePos_0[i][1],640);pre[0][i]=0;}
            	if(pre[1][i]){BitBlt(prePos_1[i][0],prePos_1[i][1],prePos_1[i][2],prePos_1[i][3],page_game,prePos_1[i][0],prePos_1[i][1],640);pre[1][i]=0;}
            	if(pre[2][i]){BitBlt(prePos_2[i][0],prePos_2[i][1],prePos_2[i][2],prePos_2[i][3],page_game,prePos_2[i][0],prePos_2[i][1],640);pre[2][i]=0;}
            	if(pre[3][i]){BitBlt(prePos_3[i][0],prePos_3[i][1],prePos_3[i][2],prePos_3[i][3],page_game,prePos_3[i][0],prePos_3[i][1],640);pre[3][i]=0;}

                //再画现在的滑块
                //trans为透明色还没有设置
            	if(song[0][i+ts] == 1){TransparentBlt(0,0,155,45,left1,targetPos_0[i][0],targetPos_0[i][1],targetPos_0[i][2],targetPos_0[i][3],trans);pre[0][i]=1;}
            	if(song[1][i+ts] == 1){TransparentBlt(0,0,145,45,left2,targetPos_1[i][0],targetPos_1[i][1],targetPos_1[i][2],targetPos_1[i][3],trans);pre[1][i]=1;}
            	if(song[2][i+ts] == 1){TransparentBlt(0,0,145,45,right1,targetPos_2[i][0],targetPos_2[i][1],targetPos_2[i][2],targetPos_2[i][3],trans);pre[2][i]=1;}
            	if(song[3][i+ts] == 1){TransparentBlt(0,0,155,45,right2,targetPos_3[i][0],targetPos_3[i][1],targetPos_3[i][2],targetPos_3[i][3],trans);pre[3][i]=1;}
            }
            LCD_ShowNum(422,412,point,105,0);
        break;

        case 2:
            if(checkBack == 0)//如果背景还没画，那就画背景图
            {
                BitBlt(0,0,640,480,page_point,0,0,640);
                checkBack = 1;
            }
            LCD_ShowNum(310,280,point,105,1);

        break;

        default:
        break;
    }

}
void CalcPos(void)
{
    if(page == 1)
    {
        if(count >= period || count <0){count = 0; ts++;}
        else count++;

        if(ts == SMAX-1+3)//歌曲结束
        {
            page = 2;//考虑增加一个结束效果
            checkBack = 0;
        }
        else
        {
            //paint target
        	for(j = 0;j<4;j++)
        		for (i=0; i<TMAX-1; i++)
        	                        {
        	                            prePos_0[i][j] = targetPos_0[i][j];
        	                            prePos_1[i][j] = targetPos_1[i][j];
        	                            prePos_2[i][j] = targetPos_2[i][j];
        	                            prePos_3[i][j] = targetPos_3[i][j];
        	                        }
            for(p=0;p<4;p++)
            {
                for(i=0;i<TMAX-1;i++)
                {
                    if(song[p][i+ts] == 1)
                    {
                        y1 = Y[i+1] + count*(Y[i]-Y[i+1])/period;
                        x1 = a[p]*y1 + b[p];
                        y2 = ((a[p]-h[p])*y1+b[p]-d[p])/(c[p]-h[p]);
                        x2 = c[p]*y2 + d[p];
                //公式x1 = a*y1+b, x2 = c*y2 +d

                        switch(p)
                        {
                            case 0:
                                targetPos_0[i][0] = x2;//x
                                targetPos_0[i][1] = y1;//y
                                targetPos_0[i][2] = x1-x2;//width
                                targetPos_0[i][3] = y2-y1;//height

                            break;

                            case 1:
                                targetPos_1[i][0] = x2;//x
                                targetPos_1[i][1] = y1;//y
                                targetPos_1[i][2] = x1-x2;//width
                                targetPos_1[i][3] = y2-y1;//height
                            break;

                            case 2:
                                targetPos_2[i][0] = x1;//x
                                targetPos_2[i][1] = y1;//y
                                targetPos_2[i][2] = x2-x1;//width
                                targetPos_2[i][3] = y2-y1;//height
                            break;

                            case 3:
                                targetPos_3[i][0] = x1;//x
                                targetPos_3[i][1] = y1;//y
                                targetPos_3[i][2] = x2-x1;//width
                                targetPos_3[i][3] = y2-y1;//height
                            break;
                            break;

                            default:
                            break;
                        }
                    }

                }
            }

        }

    }


}


int callback()
{
    switch(page)
    {
        case 0://page song
            switch(key)//keyboard
            {
                case ENTER://enter
                //    song = readsong(songorder);
                    switch(songOrder)
                    {
                        case 0: memcpy(song,song_1,sizeof(song_1));break;
                        case 1: memcpy(song,song_2,sizeof(song_2));break;
                        case 2: memcpy(song,song_3,sizeof(song_3));break;
                        default: break;
                    }
                    count = 0;
                    checkBack = 0;
                    page = 1;
                    point = 0;
                    ts=0;
                break;

                case UP://up
                    lastOrder = songOrder;
                    if(songOrder <= 0)
                        songOrder = songnumber - 1;
                    else
                        songOrder = songOrder - 1;
                break;

                case DOWN://down
                    lastOrder = songOrder;
                    if(songOrder >= songnumber - 1)
                        songOrder = 0;
                    else
                        songOrder = songOrder + 1;

                break;

                default:
                break;
            }
        break;


        case 1://page game
            switch(key)//keyboard
            {
                case LEFT1://left 1
                    if(song[0][ts]==1) {
                        Btime[0] = count;
                        point++;
                        song[0][ts]=0;
                    } else
                        Btime[0] = -1;
                break;

                case LEFT2://left 2
                    if(song[1][ts]==1) {
                        Btime[1] = count;
                        point++;
                        song[1][ts]=0;
                    } else
                        Btime[1] = -1;
                break;

                case RIGHT1://right 1
                    if(song[2][ts]==1) {
                        Btime[2] = count;
                        point++;
                        song[2][ts]=0;
                    } else
                        Btime[2] = -1;
                break;

                case RIGHT2://right 2
                    if(song[3][ts]==1) {
                        Btime[3] = count;
                        point++;
                        song[3][ts]=0;
                    } else
                        Btime[3] = -1;
                break;

                default:
                break;
            }
        break;

        case 2://page point
            switch(key)//keyboard
            {
                case RET://return to game
                    count = 0;
                    checkBack = 0;
                    ts=0;
                    page = 1;
                break;

                case SONG://return to song list
                    checkBack = 0;
                    page = 0;
                break;

                default:
                break;
            }

        break;

        default:
            //checkBack = 0;
            //page = 0;
        break;
    }




}
