from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.db.models import Prefetch
from django.shortcuts import get_object_or_404, redirect, render

from .models import Assessment, Choice, Question, TestResult


def _attach_results(assessments, user):
    """Har bir testga foydalanuvchining eng yaxshi natijasini biriktiradi."""
    best = {}
    if user.is_authenticated:
        for r in TestResult.objects.filter(user=user):
            if r.assessment_id not in best or r.score > best[r.assessment_id].score:
                best[r.assessment_id] = r
    items = []
    for a in assessments:
        result = best.get(a.id)
        items.append({'a': a, 'result': result})
    return items


def assessment_list(request):
    tab = request.GET.get('tab', 'skill')
    if tab not in ('skill', 'psych'):
        tab = 'skill'
    skill = Assessment.objects.filter(is_active=True, kind='skill')
    psych = Assessment.objects.filter(is_active=True, kind='psych')

    skill_items = _attach_results(skill, request.user)
    psych_items = _attach_results(psych, request.user)

    return render(request, 'assessments/list.html', {
        'tab': tab,
        'skill_items': skill_items,
        'psych_items': psych_items,
        'skill_done': sum(1 for i in skill_items if i['result']),
        'psych_done': sum(1 for i in psych_items if i['result']),
        'active_nav': 'assessments',
    })


@login_required
def take_test(request, pk):
    assessment = get_object_or_404(
        Assessment.objects.prefetch_related(
            Prefetch('questions', queryset=Question.objects.prefetch_related('choices'))
        ),
        pk=pk, is_active=True,
    )
    questions = list(assessment.questions.all())
    if not questions:
        messages.warning(request, 'Bu test uchun savollar hali kiritilmagan.')
        return redirect('assessments:list')

    if request.method == 'POST':
        correct = 0
        total_weight = 0
        max_weight = 0
        for q in questions:
            choice_id = request.POST.get(f'q{q.id}')
            choices = list(q.choices.all())
            if assessment.kind == 'psych':
                max_weight += max((c.weight for c in choices), default=0)
            picked = next((c for c in choices if str(c.id) == choice_id), None)
            if picked:
                if picked.is_correct:
                    correct += 1
                total_weight += picked.weight

        if assessment.kind == 'psych' and max_weight:
            score = round(total_weight / max_weight * 100, 1)
        else:
            score = round(correct / len(questions) * 100, 1)

        result = TestResult.objects.create(
            user=request.user,
            assessment=assessment,
            score=score,
            correct_answers=correct,
            total_questions=len(questions),
        )
        # Reyting balini yangilash
        profile = request.user.profile
        profile.score += int(score / 10)
        profile.save(update_fields=['score'])

        return redirect('assessments:result', pk=result.pk)

    return render(request, 'assessments/test.html', {
        'assessment': assessment,
        'questions': questions,
        'active_nav': 'assessments',
    })


@login_required
def result_view(request, pk):
    result = get_object_or_404(TestResult, pk=pk, user=request.user)
    return render(request, 'assessments/result.html', {
        'result': result,
        'active_nav': 'assessments',
    })
