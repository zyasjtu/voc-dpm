function [pos, neg, impos] = pascal_data(cls, year)

PosImageFile = 'f:/data/VOC2007/VOCdevkit/VOC2007/JPEGImages/pos.txt';
NegImageFile = 'f:/data/VOC2007/VOCdevkit/VOC2007/JPEGImages/neg.txt';
BasePath = 'f:/data/VOC2007/VOCdevkit/VOC2007/JPEGImages';

conf       = voc_config('pascal.year', year);
cachedir   = conf.paths.model_dir;
dataset_fg = conf.training.train_set_fg;

pos      = [];
impos    = [];
numpos   = 0;
numimpos = 0;
dataid   = 0;

fin = fopen(PosImageFile,'r');

now = 1;

while ~feof(fin)
    line = fgetl(fin);
    S = regexp(line,' ','split');
    count = str2num(S{2});
    if (mod(now,50) == 0)
        fprintf('%s: parsing positives (%s): %d\n', ...
                 cls, S{1}, now);
    end
    now = now + 1;
    for i = 1:count;%������ȡ������
        numpos = numpos + 1;
        dataid = dataid + 1;
        bbox = [str2num(S{i*4-1}),str2num(S{i*4}),str2num(S{i*4+1}),str2num(S{i*4+2})];
        
        pos(numpos).im      = [BasePath '/' S{1}]; %ƴ�ӵ�ַ
        pos(numpos).x1      = bbox(1);
        pos(numpos).y1      = bbox(2);
        pos(numpos).x2      = bbox(3);
        pos(numpos).y2      = bbox(4);
        pos(numpos).boxes   = bbox;
        pos(numpos).flip    = false;
        pos(numpos).trunc   = 0;%1 represent incomplete objects, 0 is complete
        pos(numpos).dataids = dataid;
        pos(numpos).sizes   = (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1);
        
        img = imread([BasePath '/' S{1}]);
        [height, width, depth] = size(img);%�����ҵ�������û�б궨��С������Ҫ��ȡ����ͼ��ߴ���ܷ�ת
        
        % Create flipped example ������ת��������
        numpos  = numpos + 1;
        dataid  = dataid + 1;
        oldx1   = bbox(1);
        oldx2   = bbox(3);
        bbox(1) = width - oldx2 + 1;
        bbox(3) = width - oldx1 + 1;
        
        pos(numpos).im      = [BasePath '/' S{1}];
        pos(numpos).x1      = bbox(1);
        pos(numpos).y1      = bbox(2);
        pos(numpos).x2      = bbox(3);
        pos(numpos).y2      = bbox(4);
        pos(numpos).boxes   = bbox;
        pos(numpos).flip    = true;
        pos(numpos).trunc   = 0;% to make operation simple
        pos(numpos).dataids = dataid;
        pos(numpos).sizes   = (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1);%���ͼ�������С   
        
    end
    
    % Create one entry per foreground image in the impos array�������pos��һ���ģ��൱�ڸ���
    numimpos                = numimpos + 1;
    impos(numimpos).im      = [BasePath '/' S{1}];
    impos(numimpos).boxes   = zeros(count, 4);
    impos(numimpos).dataids = zeros(count, 1);
    impos(numimpos).sizes   = zeros(count, 1);
    impos(numimpos).flip    = false;
    
    for j = 1:count
        dataid = dataid + 1;
        bbox   = [str2num(S{j*4-1}),str2num(S{j*4}),str2num(S{j*4+1}),str2num(S{j*4+2})];
        
        impos(numimpos).boxes(j,:) = bbox;
        impos(numimpos).dataids(j) = dataid;
        impos(numimpos).sizes(j)   = (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1);
    end     
    
    img = imread([BasePath '/' S{1}]);
    [height, width, depth] = size(img);
    
     % Create flipped example
    numimpos                = numimpos + 1;
    impos(numimpos).im      = [BasePath '/' S{1}];
    impos(numimpos).boxes   = zeros(count, 4);
    impos(numimpos).dataids = zeros(count, 1);
    impos(numimpos).sizes   = zeros(count, 1);
    impos(numimpos).flip    = true;
    unflipped_boxes         = impos(numimpos-1).boxes;
    
    
    for j = 1:count
    dataid  = dataid + 1;
    bbox    = unflipped_boxes(j,:);
    oldx1   = bbox(1);
    oldx2   = bbox(3);
    bbox(1) = width - oldx2 + 1;
    bbox(3) = width - oldx1 + 1;

    impos(numimpos).boxes(j,:) = bbox;
    impos(numimpos).dataids(j) = dataid;
    impos(numimpos).sizes(j)   = (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1);
    end
end

fclose(fin);
% Negative examples from the background dataset

fin2 = fopen(NegImageFile,'r');
neg    = [];
numneg = 0;
negnow = 0;
while ~feof(fin2)%������ѭ����ȡ������
     line = fgetl(fin2);
     if (mod(negnow,50) == 0)
         fprintf('%s: parsing Negtives (%s): %d\n', ...
                       cls, line, negnow);
     end
     negnow             = negnow +1;
     dataid             = dataid + 1;
     numneg             = numneg+1;
     neg(numneg).im     = [BasePath '/' line];
%     disp(neg(numneg).im);
     neg(numneg).flip   = false;
     neg(numneg).dataid = dataid;
 end
 
 fclose(fin2);%�洢Ϊmat�ļ� ����ѵ����������Ϣ
 save([cachedir cls '_' dataset_fg '_' year], 'pos', 'neg', 'impos');
