clear;clc;close all;
%% load Data;
data=xlsread('����ȡ���.xls','1','A2:M6141');   % ��6140   ��ȥ���м任�á���Ч���ݣ���Ч���ݶ���Ϊ���ĸ���103

% ��ȡĳһʱ�����д���
collocation=zeros(24);      %��ȡ24��ʱ�������д���
collocation_num=[];         %ÿ��ʱ�̱�����������
for i=1:24
    k=1;
    for j=1:6140
        a=collocation(i,1:22);
        b=data(j,1);
        c=data(j,2);
        if(b==i&&~ismember(c,a))
            collocation(i,k)=data(j,2);
            k=k+1;
        end
    end
    collocation_num(end+1)=k-1;
end

%% ��������ѭ��
save myfile data collocation collocation_num;                   % �������ϱ���
for collocation_order=1:collocation_num                                        %�����ñ���ѭ����
% ��ȡ����ʱ�䡢����������������
%��һ��Сʱ��5��������Ϊ���� Ԥ����һСʱ��6������
load myfile;                                                     %���ر��������
j=1;    %jΪ�����������ݵ�������
timeset=xlsread('��Ԥ�����.xls','����̨','C4:C4');                                   %������ʱ�̣�timeset��
matchset=collocation(timeset,collocation_order);                                                                       %�����ñ�����䣺matchset��
for i=1:6140
    time=data(i,1);
    match=data(i,2);
    if(time==timeset&&match==matchset)
        X(j,:)=data(i,3:7);
        Y(j,:)=data(i,8:end);
        j=j+1;
    end
end
%% 
[X_r,X_c]=size(X);          %���ĳһʱ��ѵ�����ݼ����ݲ���10��������ȡ����ʱ�̵��ض��������ѵ����
if (X_r<=10)
    j=1;
    for i=1:6140
        match=data(i,2);
        if(match==matchset)
            X(j,:)=data(i,3:7);
            Y(j,:)=data(i,8:end);
            j=j+1;
        end
    end
end

%% ��һ��
[inputn,inputps]=mapminmax(X',0,1);
X=inputn';
[outputn,outputps]=mapminmax(Y',0,1);
Y=outputn';

%% �������ݼ�
rand('state',0)
r=randperm(size(X,1));
divide = 0.8                                 %                                  ������ѵ��������Լ��Ļ��ֱ�����divide��
ntrain =floor( size(X,1)*divide ) ;          % ����ѵ���������Լ�
Xtrain = X(r(1:ntrain),:);       % ѵ��������
Ytrain = Y(r(1:ntrain),:);       % ѵ�������
Xtest  = X(r(ntrain+1:end),:);   % ���Լ�����
Ytest  = Y(r(ntrain+1:end),:);   % ���Լ����

[Ytest_r,Ytest_c]=size(Ytest)    % ���Լ�������������������Լ������ά�ȡ�����������
[Ytrain_r,Ytrain_c]=size(Ytrain)    % ���Լ�������������������Լ������ά�ȡ�����������

%% û�Ż���msvm
% ��������ͷ�������˲���
C    = 1000*rand;%�ͷ�����
par  = 1000*rand;%�˲���
ker  = 'rbf';
tol  = 1e-20;
epsi = 1;
% ѵ��
[Beta,NSV,Ktrain,i1] = msvr(Xtrain,Ytrain,ker,C,epsi,par,tol);
% ����
Ktest = kernelmatrix(ker,Xtest',Xtrain',par);
Ypredtest = Ktest*Beta;

% ����������
mse_test=sum(sum((Ypredtest-Ytest).^2))/(size(Ytest,1)*size(Ytest,2))
 
% ����һ��
yuce=mapminmax('reverse',Ypredtest',outputps);yuce=yuce';
zhenshi=mapminmax('reverse',Ytest',outputps);zhenshi=zhenshi';

%% ����Ⱥ�Ż������֧��������
[y ,trace]=psoformsvm(Xtrain,Ytrain,Xtest,Ytest);
%% ���õõ����ųͷ�������˲�������ѵ��һ��֧��������
C    = y(1);%�ͷ�����
par  = y(2);%�˲���
[Beta,NSV,Ktrain,i1] = msvr(Xtrain,Ytrain,ker,C,epsi,par,tol);
Ktest = kernelmatrix(ker,Xtest',Xtrain',par);
Ypredtest_pso = Ktest*Beta;
% ���
pso_mse_test=sum(sum((Ypredtest_pso-Ytest).^2))/(size(Ytest,1)*size(Ytest,2))
% ����һ�� 
yuce_pso=mapminmax('reverse',Ypredtest_pso',outputps);yuce_pso=yuce_pso';
subtraction=yuce_pso-zhenshi;

%% ���ֱ����ַ���
match_char =num2str(matchset);      %����������ַ���
time_char  =num2str(timeset) ;      %��ʱ���ַ���

sum_number=num2str(size(X,1));      %���ݼ������ַ���
divide_char=num2str(divide);        %�����ݼ����ֱ����ַ���
Ytrain_r_char=num2str(Ytrain_r);    %ѵ���������ַ���
Ytest_r_char=num2str(Ytest_r);      %���Լ������ַ���

%% 6��ָ���غ϶ȼ���                                                    ��ָ���������޸ġ�
repeat=zeros(1,Ytest_c);                                                        %�������ָ���ظ��ȣ�repeat��
error =zeros(1,Ytest_c);
for i=1:Ytest_c
    for j=1:Ytest_r
        repeat(i)=repeat(i)+(zhenshi(j,i)-yuce_pso(j,i))^2;
        
    end
    repeat(i)=repeat(i)/Ytest_r;
    error(i) =max(abs(yuce_pso(:,i)-zhenshi(:,i)));         %������ֵ�����ֵ
end

%% Ԥ��������
input_Xtest=xlsread('��Ԥ�����.xls','����̨','D4:H4'); 
input_Xtest = [Xtest;input_Xtest];
Ktest = kernelmatrix(ker,input_Xtest',Xtrain',par);
Output_Ypredtest_pso = Ktest*Beta;
% ���
Output_pso_mse_test=sum(sum((Ypredtest_pso-Ytest).^2))/(size(Ytest,1)*size(Ytest,2))
% ����һ�� 
Output_yuce_pso=mapminmax('reverse',Output_Ypredtest_pso',outputps);Output_yuce_pso=Output_yuce_pso';
Output_yuce_pso = Output_yuce_pso (end,:);
%% д���ļ�
cellnames_1=['C',num2str(collocation_order+7),':H',num2str(collocation_order+7)];
cellnames_2=['B',num2str(collocation_order+7),':B',num2str(collocation_order+7)];
cellnames_3=['I',num2str(collocation_order+7),':N',num2str(collocation_order+7)];
cellnames_4=['P',num2str(collocation_order+7),':U',num2str(collocation_order+7)];

xlswrite('��Ԥ�����.xls',Output_yuce_pso,'����̨',cellnames_1)         %д��Ԥ��
xlswrite('��Ԥ�����.xls',matchset,'����̨',cellnames_2)                %д�����
xlswrite('��Ԥ�����.xls',error,'����̨',cellnames_3)                   %д��������
xlswrite('��Ԥ�����.xls',repeat,'����̨',cellnames_4)                  %д���ظ���


%% ��ͼ
% figure_name1=[time_char,'ʱ��,',match_char,'��������','��Ӧ��Ѱ������'];
% figure('NumberTitle', 'off', 'Name',figure_name1);
% plot(trace)
% grid on;
% xlabel('��������')
% ylabel('��Ӧ��ֵ')
% title('psosvm��Ӧ�����ߣ�Ѱ�����ߣ�')

%% ��ͼ ������Ԥ��ά��Ԥ��ֵ����ʵֵ�Ĳ���ͼ��
figure_name2=[time_char,'ʱ��,',match_char,'��������','���Լ�Ԥ��ֵ����ʵֵ����ָ��Ĳ�ֵ���������ݼ�Ϊ',sum_number,'��,ѵ����Ϊ',Ytrain_r_char,'�������Լ�Ϊ',Ytest_r_char,'����'];
figure('NumberTitle', 'off', 'Name', figure_name2);
t=0:1:Ytest_r-1;axis([0 Ytest_r-1 -inf inf])
for i=1:Ytest_c
    subplot(2,3,i)
    hold on;grid on;
    plot(t,subtraction(:,i),'-r*')
    switch (i)
        case 1
            title('3#Ƶ����ʵ��Ԥ��');xlabel('X');ylabel('��С')
        case 2
            title('6#Ƶ����ʵ��Ԥ��');xlabel('X');ylabel('��С')
        case 3
            title('�ܻ�ˮ����ʵ��Ԥ��');xlabel('X');ylabel('��С')
        case 4
            title('��ˮ��ѹ����ʵ��Ԥ��');xlabel('X');ylabel('��С')
        case 5
            title('һ��������ʵ��Ԥ��');xlabel('X');ylabel('��С')
        case 6
            title('һ��������ʵ��Ԥ��');xlabel('X');ylabel('��С')
    end
end

%% ��ͼ                                                               ������Ԥ��ά������ʵֵ�Աȣ�����ͼ��2*3��ͼ��
figure_name3=[time_char,'ʱ��,',match_char,'��������','���Լ�Ԥ��ֵ����ʵֵ�Աȡ��������ݼ�Ϊ',sum_number,'��,ѵ����Ϊ',Ytrain_r_char,'�������Լ�Ϊ',Ytest_r_char,'����'];
figure('NumberTitle', 'off', 'Name', figure_name3);
t=0:1:Ytest_r-1;axis([0 Ytest_r-1 -inf inf])
for i=1:Ytest_c
    subplot(2,3,i)
    plot(t,zhenshi(:,i),'-bp')
    hold on;grid on;
    plot(t,yuce_pso(:,i),'-r*')
    switch (i)
        case 1
            legend('3#Ƶ����ʵֵ','3#Ƶ��Ԥ��ֵ','Location','SouthEast')
            title('3#Ƶ����ʵ��Ԥ��');xlabel('X');ylabel('��С')
        case 2
            legend('6#Ƶ����ʵֵ','6#Ƶ��Ԥ��ֵ','Location','SouthEast')
            title('6#Ƶ����ʵ��Ԥ��');xlabel('X');ylabel('��С')
        case 3
            legend('�ܻ�ˮ����ʵֵ','�ܻ�ˮ��Ԥ��ֵ','Location','SouthEast')
            title('�ܻ�ˮ����ʵ��Ԥ��');xlabel('X');ylabel('��С')
        case 4
            legend('��ˮ��ѹ����ʵֵ','��ˮ��ѹ��Ԥ��ֵ','Location','SouthEast')
            title('��ˮ��ѹ����ʵ��Ԥ��');xlabel('X');ylabel('��С')
        case 5
            legend('һ��������ʵֵ','һ������Ԥ��ֵ','Location','SouthEast')
            title('һ��������ʵ��Ԥ��');xlabel('X');ylabel('��С')
        case 6
            legend('һ��������ʵֵ','һ������Ԥ��ֵ','Location','SouthEast')
            title('һ��������ʵ��Ԥ��');xlabel('X');ylabel('��С')
    end
end     
clear;
end

save data_svm_psosvm 