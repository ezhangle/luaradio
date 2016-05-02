local radio = require('radio')

if #arg < 1 then
    io.stderr:write("Usage: " .. arg[0] .. " <frequency>\n")
    os.exit(1)
end

local frequency = tonumber(arg[1])
local offset = -200e3
local baudrate = 1200

local top = radio.CompositeBlock()
local source = radio.RtlSdrSource(frequency + offset, 1000000)
local tuner = radio.TunerBlock(offset, 12e3, 80)
local space_filter = radio.ComplexBandpassFilterBlock(129, {3500, 5500})
local space_magnitude = radio.ComplexMagnitudeBlock()
local mark_filter = radio.ComplexBandpassFilterBlock(129, {-5500, -3500})
local mark_magnitude = radio.ComplexMagnitudeBlock()
local subtractor = radio.SubtractBlock()
local data_filter = radio.LowpassFilterBlock(128, baudrate)
local clock_recovery = radio.ZeroCrossingClockRecoveryBlock(baudrate)
local sampler = radio.SamplerBlock()
local bit_slicer = radio.SlicerBlock()
local framer = radio.POCSAGFrameBlock()
local decoder = radio.POCSAGDecodeBlock()
local sink = radio.JSONSink()

local plot1 = radio.GnuplotSpectrumSink(2048, 'RF Spectrum', {yrange = {-120, -40}})
local plot2 = radio.GnuplotPlotSink(2048, 'Demodulated Bitstream')

top:connect(source, tuner)
top:connect(tuner, space_filter, space_magnitude)
top:connect(tuner, mark_filter, mark_magnitude)
top:connect(mark_magnitude, 'out', subtractor, 'in1')
top:connect(space_magnitude, 'out', subtractor, 'in2')
top:connect(subtractor, data_filter, clock_recovery)
top:connect(data_filter, 'out', sampler, 'data')
top:connect(clock_recovery, 'out', sampler, 'clock')
top:connect(sampler, bit_slicer, framer, decoder, sink)
top:connect(tuner, plot1)
top:connect(data_filter, plot2)
top:run()
