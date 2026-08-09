from datetime import date, datetime

from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.shortcuts import redirect, render
from django.utils import timezone
from django.views.decorators.http import require_POST

from community.models import Event, EventAttendance

from .models import AttendanceRecord, KpiCategory, WorkZone
from .utils import distance_meters


@login_required
def attendance(request):
    today = timezone.localdate()
    today_gps = AttendanceRecord.objects.filter(
        user=request.user, date=today, method='gps'
    ).first()
    records = AttendanceRecord.objects.filter(user=request.user)[:30]
    event_attendances = (
        EventAttendance.objects.filter(user=request.user).select_related('event')
    )
    upcoming_events = Event.objects.filter(is_active=True, date__gte=today)[:5]
    return render(request, 'performance/attendance.html', {
        'zone': WorkZone.objects.filter(is_active=True).first(),
        'today_gps': today_gps,
        'records': records,
        'event_attendances': event_attendances,
        'upcoming_events': upcoming_events,
        'active_nav': 'profile',
    })


@login_required
@require_POST
def gps_check_in(request):
    now = timezone.localtime()
    zone = WorkZone.objects.filter(is_active=True).first()
    latitude = request.POST.get('latitude') or None
    longitude = request.POST.get('longitude') or None

    # Ish hududi belgilangan bo'lsa, joylashuv radius ichida ekani tekshiriladi.
    if zone is not None:
        if not latitude or not longitude:
            messages.error(request, 'Joylashuv aniqlanmadi. Brauzerda geolokatsiyaga ruxsat bering.')
            return redirect('performance:attendance')
        distance = distance_meters(
            float(latitude), float(longitude), zone.latitude, zone.longitude)
        if distance > zone.radius_meters:
            messages.error(
                request,
                f'Siz ish hududidan tashqaridasiz ({distance} metr). Davomat belgilanmadi.',
            )
            return redirect('performance:attendance')

    record, created = AttendanceRecord.objects.get_or_create(
        user=request.user, date=now.date(), method='gps',
        defaults={
            'check_in': now.time(),
            'status': 'late' if now.hour >= 9 else 'present',
            'location_name': (request.POST.get('location_name')
                              or (zone.name if zone else 'Ish joyi')),
            'latitude': latitude,
            'longitude': longitude,
        },
    )
    if created:
        messages.success(request, f'Davomat belgilandi: {record.check_in:%H:%M}')
    elif not record.check_out:
        record.check_out = timezone.localtime().time()
        record.save(update_fields=['check_out'])
        messages.success(request, f'Ketish vaqti belgilandi: {record.check_out:%H:%M}')
    else:
        messages.info(request, 'Bugungi davomat allaqachon yakunlangan.')
    return redirect('performance:attendance')


@login_required
@require_POST
def qr_check_in(request):
    code = request.POST.get('qr_code', '').strip()
    event = Event.objects.filter(qr_code=code, is_active=True).first() if code else None
    if not event:
        messages.error(request, 'QR kod topilmadi yoki muddati tugagan.')
        return redirect('performance:attendance')
    _, created = EventAttendance.objects.get_or_create(
        user=request.user, event=event, defaults={'via_qr': True}
    )
    if created:
        messages.success(request, f'"{event.title}" tadbirida davomat belgilandi!')
    else:
        messages.info(request, 'Bu tadbirda davomat allaqachon belgilangan.')
    return redirect('performance:attendance')


@login_required
def kpi(request):
    categories = KpiCategory.objects.prefetch_related('items')
    cat_data = []
    total = 0
    count = 0
    for cat in categories:
        items = [i for i in cat.items.all() if i.user_id == request.user.id]
        if not items:
            continue
        for i in items:
            total += i.percent
            count += 1
        cat_data.append({'category': cat, 'items': items})
    overall = round(total / count) if count else 0
    return render(request, 'performance/kpi.html', {
        'cat_data': cat_data,
        'overall': overall,
        'active_nav': 'profile',
    })
