local Timer = {};
local start = os.clock();

function Timer.start()
    start = os.clock();
end

function Timer.stop()
    return os.clock() - start;
end

return Timer;