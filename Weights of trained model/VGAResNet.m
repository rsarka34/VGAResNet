clc;
clear all;
close all;
%% Load the Data
% load feature.mat;
load copd_normal_labels.mat; load copd_normal_sigs.mat;
cat_labels=categorical(copd_normal_labels);
window=4000*5;
 for j=1:1:window
     vector(j)=j;
 end
%% feature pipeline
melspect=[];
tic
clc
for i=1:10780
    disp(['iteration==>' num2str(i)])
    sig=copd_normal(:,i);
    HVG = fast_NVG(sig,vector(1,:),'u',0); 
    HVG_adj_Matrix=full(HVG);
    im =HVG_adj_Matrix;% ind2rgb(im2uint8(rescale(HVG_adj_Matrix_normal)),jet);    
    im_r=imresize(im,[64 64]);
    feature(:,:,i)=im_r;
end
toc
adj_img=reshape(feature,[64,64,1,10780]);
%% Run from Here
adj_img=reshape(feature,[64,64,1,10780]);
load copd_normal_labels.mat;
copd_normal_labels=categorical(copd_normal_labels);
layers = [
    imageInputLayer([64, 64 1],'Name','Image Input')
    
    convolution2dLayer(5,64,'Padding','same')
    batchNormalizationLayer('Name','bn_1')
    reluLayer('Name','relu_1')
    
    convolution2dLayer(3,32,'Padding','same','Stride',2)
    batchNormalizationLayer('Name','bn_2')
    reluLayer('Name','relu_2')
    additionLayer(2,'Name','add1')
  
    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer('Name','bn_3')
    reluLayer('Name','relu_3')

    convolution2dLayer(3,16,'Padding','same','Stride',2)
    reluLayer
    additionLayer(2,'Name','add2')
    dropoutLayer
    fullyConnectedLayer(400)
    dropoutLayer(0.3)
    fullyConnectedLayer(100)
    dropoutLayer(0.2)
    fullyConnectedLayer(2)
    softmaxLayer
    classificationLayer];

lgraph = layerGraph(layers);

skipConv1 = convolution2dLayer(1,32,'Stride',2,'Name','skipConv1');
skipConv2 = convolution2dLayer(1,16,'Stride',2,'Name','skipConv2');
lgraph = addLayers(lgraph,skipConv1);
lgraph = connectLayers(lgraph,'relu_1','skipConv1');
lgraph = connectLayers(lgraph,'skipConv1','add1/in2');
lgraph = addLayers(lgraph,skipConv2);
lgraph = connectLayers(lgraph,'relu_3','skipConv2');
lgraph = connectLayers(lgraph,'skipConv2','add2/in2');


analyzeNetwork(lgraph)
%%
% K Fold Cross Validation Test
c = cvpartition(10780,'Kfold',5);
clc;
% Initialize an array to store the performance metrics for each fold
accuracy = zeros(1, 5);
% Loop over each fold
for i = 1:4
    idxTrain = training(c,i);
    train_fea=adj_img(:,:,:,idxTrain);
    idxTest=test(c,i);
    test_fea = adj_img(:,:,:,idxTest);

    train_labels=copd_normal_labels(idxTrain);
    test_labels=copd_normal_labels(idxTest);
    %
    miniBatchSize =128;
    validationFrequency =floor(numel(train_labels)/miniBatchSize);
    options = trainingOptions('adam', ...
    'ExecutionEnvironment','auto',...
    'InitialLearnRate',0.008, ...
    'MaxEpochs',90, ...
    'MiniBatchSize',miniBatchSize, ...
    'Shuffle','every-epoch', ...
    'Plots','training-progress', ...
    'Verbose',false, ...
    'ValidationData',{single(test_fea),test_labels}, ...
    'ValidationFrequency',validationFrequency,'Plots','training-progress');
    %
    lungNet_f = trainNetwork(train_fea,train_labels,lgraph,options);
    classNames = lungNet_f.Layers(22).Classes;
    % Evaluate the model on the validation data
    
    [YTestLungNet_f,scoresLungNet_f] = classify(lungNet_f,test_fea);
    rocLungNet = rocmetrics(test_labels,scoresLungNet_f,classNames);
    
    visua_fea=[];
    layer = 20;
    name = lungNet_f.Layers(layer).Name;
    for j=1:size(test_fea,4)
    act1 = activations(lungNet_f,test_fea(:,:,:,j),name);
    visua_fea(j,:)=act1;
    end
   
    %
    Y = tsne(visua_fea,'Algorithm','exact','Distance','chebychev');
    figure(400+i)
    gscatter(Y(:,1),Y(:,2),test_labels,'br','..');grid on;
    xlabel('Dimension 1','FontSize', 10);
    ylabel('Dimension 2','FontSize', 10)


    figure(500+i)
    plot(rocLungNet,ShowModelOperatingPoint=false)
    legend(classNames)

    cm=confusionchart(test_labels,YTestLungNet_f);
    figure(200+i)
    confusionchart(test_labels,YTestLungNet_f)
    

    % model name
    model_name=(['lungNet_fold_' num2str(i) '.mat']);
    save(model_name,'lungNet_f');

end


