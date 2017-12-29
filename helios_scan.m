function [out_x,out_y] = helios_scan(type, samplesize, wl_min, wl_max, steps)

%type = 1, 2, 3

% samplesize = 10;
% wl_min = 0;
% wl_max = 11000;
% steps = 500;

s = instrfind('Type', 'serial', 'Port', 'COM1', 'Tag', '');

% Create the serial port object if it does not exist
% otherwise use the object that was found.
if isempty(s)
    s = serial('COM2');
else
    fclose(s);
    s = serial('COM2');
end

s.baudrate = 9600;
s.parity = 'none';
s.terminator = 'CR/LF';
s.timeout = 10;
fopen(s);
fprintf(s, 'BUS');
while s.bytesavailable == 0
end
ret = fscanf(s);
while(ret ~= '-')
    while s.bytesavailable == 0
    end
    ret = fscanf(s);
end

switch type;
case 1 % Absorbance
   fprintf(s, 'MOD A');
   diviser = 1000;
case 2 % Transmittance / %
   fprintf(s, 'MOD T');
   diviser = 100;
case 3 % Intensity
   fprintf(s, 'MOD I');
   diviser = 1;
end

while s.bytesavailable == 0
end
ret = fscanf(s);
while(ret ~= '-')
    while s.bytesavailable == 0
    end
    ret = fscanf(s);
end

fprintf(s, 'LAM A');
while s.bytesavailable == 0
end
ret = fscanf(s);
while(ret ~= '-')
    while s.bytesavailable == 0
    end
    ret = fscanf(s);
end



i = wl_min;
j = 1;
entries = (wl_max-wl_min)/steps;
x=zeros(entries,1);
y=zeros(entries,1);

while i < wl_max
    if i > 0
        

        cmd = sprintf('WDR %d', i); 
        fprintf(s,cmd);
        while s.bytesavailable == 0
        end
        ret = fscanf(s);
        while(ret ~= '-')
            while s.bytesavailable == 0
                %pause(3);
            end
            ret = fscanf(s);
        end


        tic
        for k = 1:samplesize
            fprintf(s, 'RUN');
            while s.bytesavailable == 0
            end
            ret = fscanf(s);
            x(j) = i;

            if(str2num(ret))
                y(j) = y(j)+(str2num(ret(2:end))/diviser);
                %table(1,j) = i;
                %table(2,j) = str2num(ret);
            end

            while(ret ~= '-')
                while s.bytesavailable == 0
                    %disp(['Data not ready for wavelength ' int2str(i) ', pausing 3 seconds']);
                    %pause(1);
                end
                ret = fscanf(s);
            end
        end
        toc
        y(j) = y(j) / samplesize; 
        j = j + 1;
    end
    i = i + steps;
end


fclose(s)
delete(s)
clear s
out_x = x;
out_y = y;
end