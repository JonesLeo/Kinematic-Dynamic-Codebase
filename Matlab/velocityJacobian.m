function [Jv, JvDot] = velocityJacobian( linkList, paramList, paramRateList)
%VELOCITYJACOBIAN Summary of this function goes here
%
% [Jv, JvDot] = velocityJacobian(linkList, paramList,paramRateList) Now a more description 
%  multiline description of the function would be appropriate.
% 
% Jv = velcoity jacobian
% Jvdot = velocity hessian
% 
% linkList = the current joint angles/distances. (an Nx1 array)
% paramList= the current joint angle/distance speeds. (an Nx1 array)

%% Initialization of variables

a = zeros(6,1);
d = zeros(6,1);
alpha = zeros(6,1);
theta = zeros(6,1);
isRotary = zeros(6,1);

d_dot = zeros(6,1);
theta_dot = zeros(6,1);

for i = 1:6
    a(i) = linkList(i).a;
    alpha(i) = linkList(i).alpha;
    isRotary(i) = linkList(i).isRotary;
    if isRotary(i) == 0                     % For Prismatic
        theta(i) = linkList(i).theta;
        d(i) = paramList(i);
        if exist('paramRateList','var')
            d_dot(i) = paramRateList(i);
        end
    else   % Rotary
        d(i) = linkList(i).d;
        theta(i) = paramList(i);
        if exist('paramRateList','var')
            theta_dot(i) = paramRateList(i);
        end
    end
end

for i = 1:6
    T(:,:,i) = zeros(4,4)
end
dd = zeros(3,7);
Z = zeros(3,6);
w = zeros(3,7);
dd_dot = zeros(3,7);
 H = eye(4);
for i = 1:6
    T(:,:,i)=H*dhTransform(a(i),d(i),alpha(i),theta(i));
    H = T(:,:,i);
end
    


dd(:,1:1) = [0; 0; 0];
Z(:,1) = [0 0 1];
w(:,1:1) = [0; 0; 0];
dd_dot(:,1:1) = [0; 0; 0];
for i = 2:7
    dd(:,i:i) =  T(1:3,4:4,i-1);
    Z(:,i) = T(1:3,3:3,i-1);
    if isRotary(i-1) == 1 
        w(:,i) = theta_dot(i-1)*Z(:,i-1)+w(:,i-1);
    else
        w(:,i) = w(:,i-1);
    end
    if isRotary(i-1) == 1 
        dd_dot(:,i) = dd_dot(:,i-1) + cross(w(:,i),(dd(:,i)-dd(:,i-1)));
    else 
        dd_dot(:,i) = dd_dot(:,i-1) + cross(w(:,i),(dd(:,i)-dd(:,i-1))) + d_dot(i-1)*Z(:,i-1);
    end
    
end

%% Velocity Jacobain
for i = 1:6
    if isRotary(i) == 1             % Rotary
        Jv(1:3,i:i) = cpMap(Z(:,i))*(T(1:3,4,6)-dd(:,i));
        Jv(4:6,i:i) = Z(:,i);
    else       % Prismatic
        Jv(1:3,i:i) = Z(:,i);
        Jv(4:6,i:i) = [0; 0; 0];
    end
end

%% Velcoity hessian (Jv_dot) 

JvDot = zeros(6,6);

if exist('paramRateList','var')
    for i = 1:6
        if isRotary(i) == 1             % Rotary
            JvDot(:,i) = [cross(cross(w(:,i),Z(:,i)),(dd(:,7)-dd(:,i)))+cross(Z(:,i),dd_dot(:,7)-dd_dot(:,i)); cross(w(:,i),Z(:,i))];
        else       % Prismatic
            JvDot(:,i) = [cross(w(:,i),Z(:,i)); 0; 0; 0];
        end
    end
else
    JvDot = [];
end
end
