from django import forms

from .models import Profile


class ProfileForm(forms.ModelForm):
    first_name = forms.CharField(
        label='Ism', max_length=50, required=False,
        widget=forms.TextInput(attrs={'class': 'input'})
    )
    last_name = forms.CharField(
        label='Familiya', max_length=50, required=False,
        widget=forms.TextInput(attrs={'class': 'input'})
    )

    class Meta:
        model = Profile
        fields = ['phone', 'region', 'specialty', 'birth_date', 'bio']
        widgets = {
            'phone': forms.TextInput(attrs={'class': 'input', 'placeholder': '+998 90 000 00 00'}),
            'region': forms.Select(attrs={'class': 'input'}),
            'specialty': forms.TextInput(attrs={'class': 'input'}),
            'birth_date': forms.DateInput(attrs={'class': 'input', 'type': 'date'}),
            'bio': forms.Textarea(attrs={'class': 'input', 'rows': 3}),
        }

    def save(self, commit=True):
        profile = super().save(commit=commit)
        user = profile.user
        user.first_name = self.cleaned_data.get('first_name', user.first_name)
        user.last_name = self.cleaned_data.get('last_name', user.last_name)
        if commit:
            user.save()
        return profile
