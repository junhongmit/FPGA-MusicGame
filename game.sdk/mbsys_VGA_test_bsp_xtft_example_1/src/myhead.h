#ifndef MYHEAD_H_INCLUDED
#define MYHEAD_H_INCLUDED


//*********************************************************
#define SMAX 60//��������
#define TMAX 4//ÿ������������
#define W 640//��Ļ����
#define H 480//��Ļ�߶�
#define songnumber 3//��������
#define period 10//����ѭ��
#define L 210//��������
#define trans 0xFFFFFFFF

//keys
#define ENTER 0x5A
#define UP 117
#define DOWN 114
#define LEFT1 0x23
#define LEFT2 0x2B
#define RIGHT1 0x3B
#define RIGHT2 0x42
#define RET   0x2D
#define SONG  0x1B


double a[4] ={(double)W/8/(L-H),             0,   0,   (double)W/8/(H-L)};
double b[4] ={(double)(2*L-3*H)*W/8/(L-H), (double)W/2, (double)W/2, (double)W*(5*H-6*L)/8/(H-L)};
double c[4] = {(double)W/4/(L-H),    (double)W/8/(L-H),          (double)W/8/(H-L),           (double)W/4/(H-L)};
double d[4] = {-H*(double)W/4/(L-H), (2*L-3*H)*(double)W/8/(L-H),(double)W*(5*H-6*L)/8/(H-L), (3*H-4*L)*(double)W/4/(H-L)};

double h[4] = {-3.444,-3.222,3.222,3.444};//�ĸ�(x2-x1)/(y2-y1)�Ĳ���
int Y[5] = {/*435,*/ 379, 323, 266,210, 0};//�����ʼ��Ĳ���

//*************************
int song[4][SMAX] = {0};
int song_1[4][SMAX] = {{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,1,1,1,1,1,1,0,0,1,1,1,1,1,1,0,0,1,0,0,0,0,0,0,0,1,1,1,1},
                    {0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,1,1,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,1,0,0,0,0},
                    {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,1,0,0,0,1,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,1,0,0,0,0,0,0,0,0,0},
                    {0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,1,1,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0}
                };
int song_2[4][SMAX] = {{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,1,1,1,1,1,1,0,0,1,1,1,1,1,1,0,0,1,0,0,0,0,0,0,0,1,1,1,1},
                    {0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,1,1,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,1,0,0,0,0},
                    {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,1,0,0,0,1,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,1,0,0,0,0,0,0,0,0,0},
                    {0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,1,1,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0}
                };
int song_3[4][SMAX] = {{0,0,0,0,0,0,0,0,0,1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,1,1,1,1,1,1,0,0,1,1,1,1,1,1,0,0,1,0,0,0,0,0,0,0,1,1,1,1},
                    {0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,1,1,0,0,0,0,0,1,0,0,1,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,1,0,0,0,0},
                    {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,1,0,0,0,1,0,0,0,0,1,0,0,1,1,0,0,0,0,0,0,1,1,0,0,1,0,0,0,0,0,0,0,0,0},
                    {0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,1,1,0,0,0,0,1,1,0,0,0,1,0,1,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0}
                };


int page = 0;
//int song[4,SMAX] = {0};
int ts = 0;
int count = 0;

int point = 0;
int songOrder = 0;
int lastOrder = 0;
int Btime[4] = {0};
int checkBack = 0;

//��¼λ�ã����ڻ�����
//4�зֱ�Ϊx,y,wid,hei
int targetPos_0[TMAX][4] = {0};
int targetPos_1[TMAX][4] = {0};
int targetPos_2[TMAX][4] = {0};
int targetPos_3[TMAX][4] = {0};
//���ڼ�¼��һ�ε�λ��
int prePos_0[TMAX][4] = {0};
int prePos_1[TMAX][4] = {0};
int prePos_2[TMAX][4] = {0};
int prePos_3[TMAX][4] = {0};


int i=0,p = 0,j=0;//temp variable
int x = 0, y = 0, size = 0;//temp variable

double x1=0,y1=0,x2=0,y2=0;
//double x0=0,y0=0,width0=0,height0=0;

//*****************************************************************

#endif // MYHEAD_H_INCLUDED
